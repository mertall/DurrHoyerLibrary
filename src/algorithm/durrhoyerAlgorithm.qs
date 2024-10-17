namespace durrhoyerAlgorithm {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Random;
    open Microsoft.Quantum.Core;   
    open Microsoft.Quantum.Diagnostics;

    function CountElements(list : Int[], comparison : Int -> Bool) : Int {
    mutable count = 0;

    for element in list {
        if comparison(element) {
            set count += 1;
        }    
    }

    return count;
    }

    /// Converts an integer to its binary representation as an array of Results.
    /// The least significant bit is at index 0.
    function ConvertToBinary(value : Int, length : Int) : Result[] {
        // Validate input
        if (length <= 0) {
            fail "Length must be a positive integer.";
        }

        // Ensure the value fits within the specified length
        let maxVal = (1 <<< length) - 1;
        if (value < 0 or value > maxVal) {
            fail $"Value {value} cannot be represented with {length} bits.";
        }

        // Initialize the binary array with default values
        mutable binary : Result[] = [];

        // Generate the binary array
        for i in 0..length - 1 {
            let bitValue = value &&& (1 <<< i); // Extract the i-th bit
            let res = if (bitValue != 0) { One } else { Zero }; // Determine Result
            // Correct syntax to assign to the array
            set binary += [res];

        }

        // Return the constructed binary array
        return binary;
    }

    operation IntArrToQubits(bits : Int[], qubits : Qubit[]) : Unit {
        for i in 0 .. Length(bits) - 1 {
            if bits[i] == 1 {
                X(qubits[i]); // Flip qubit to |1⟩ if bit is 1
            }
        }
}
    /// # Summary
    /// Oracle that flips the phase of the target qubit when clause qubits match the specified clause.
    /// Equivalent to a multi-controlled X gate with a specific control state.
    operation OracleLessThan(clause : Int, clauseQubits : Qubit[], output : Qubit) : Unit is Adj + Ctl {
        // Determine the number of control qubits
        let n = Length(clauseQubits);

        // Convert the clause integer to an n-bit binary representation
        let clauseBinary = ConvertToBinary(clause, n);

        // Begin the within-apply block for phase kickback
        within {
            // Prepare the output qubit in the state (|0⟩ - |1⟩)/√2 for phase kickback
            X(output);
            H(output);

            // Apply X gates to clause qubits where the clause binary has '0'
            for index in 0 .. n - 1 {
                if (clauseBinary[index] == Zero) {
                    X(clauseQubits[index]);
                }
            }
        } apply {
            // Apply a multi-controlled X gate, which will induce a phase flip due to the prepared output qubit
            Controlled X(clauseQubits, output);
        }

        // Revert the X gates on the clause qubits to restore their original state
        for index in 0 .. n - 1 {
            if (clauseBinary[index] == Zero) {
                X(clauseQubits[index]);
            }
        }
    }



    /// Oracle that marks elements less than the threshold using a multi-bit comparator
    /// Excluded Indices is a list of 0 and 1s classicaly, converted to qubits of 0 and 1, where N is length of inputQubits
    operation OracleMoreThan(clause : Int, clauseQubits : Qubit[], output : Qubit) : Unit is Adj + Ctl {
        // Determine the number of control qubits
        let n = Length(clauseQubits);

        // Convert the clause integer to an n-bit binary representation
        let clauseBinary = ConvertToBinary(clause, n);

        // Begin the within-apply block for phase kickback
        within {
            // Prepare the output qubit in the state (|0⟩ - |1⟩)/√2 for phase kickback
            X(output);
            H(output);

            // Apply X gates to clause qubits where the clause binary has '0'
            for index in 0 .. n - 1 {
                if (clauseBinary[index] == One) {
                    X(clauseQubits[index]);
                }
            }
        } apply {
            // Apply a multi-controlled X gate, which will induce a phase flip due to the prepared output qubit
            Controlled X(clauseQubits, output);
        }

        // Revert the X gates on the clause qubits to restore their original state
        for index in 0 .. n - 1 {
            if (clauseBinary[index] == One) {
                X(clauseQubits[index]);
            }
        }
    }

    operation PrepareUniform(inputQubits : Qubit[]) : Unit is Adj + Ctl {
        for q in inputQubits {
            H(q);
        }
    }
    /// # Summary
    /// Reflects about the all-ones state.
    operation ReflectAboutAllOnes(inputQubits : Qubit[]) : Unit {
        Controlled Z(Most(inputQubits), Tail(inputQubits));
    }
    /// # Summary
    /// Implements the Grover diffusion operator (inversion about the mean)
    operation DiffusionOperator(inputQubits : Qubit[]) : Unit {
        within {
            // Transform the uniform superposition to all-zero.
            Adjoint PrepareUniform(inputQubits);
            // Transform the all-zero state to all-ones
            for q in inputQubits {
                X(q);
            }
        } apply {
            // Now that we've transformed the uniform superposition to the
            // all-ones state, reflect about the all-ones state, then let the
            // within/apply block transform us back.
            ReflectAboutAllOnes(inputQubits);
        }
    }


    // Grover iteration with the oracle and diffusion operator for min
    operation GroverIterationMin(threshold : Int, inputQubits : Qubit[], auxQubit : Qubit, iterations: Int) : Unit {
        OracleLessThan(threshold, inputQubits, auxQubit);
        for i in 1 .. iterations {
            DiffusionOperator(inputQubits);
        }
    }

    // Grover iteration with the oracle and diffusion operator for max
    operation GroverIterationMax(threshold : Int, inputQubits : Qubit[], auxQubit : Qubit, iterations: Int) : Unit {
        OracleMoreThan(threshold, inputQubits, auxQubit);
        for i in 1 .. iterations {
            DiffusionOperator(inputQubits);
        }
    }
    
    // Dürr-Høyer for finding min or max algorithm
    operation DurrHoyerAlgorithmProduction(
    list : Int[],
    nQubits : Int,
    type : String,
    candidate : Int,
    listSize : Int,
    iterations : Int
    ) : Result[] {
        // Initial candidate (passed as parameter)
        let threshold = list[candidate];

        use inputQubits = Qubit[nQubits];
        use auxQubit = Qubit();

        // Prepare the superposition state
        ApplyToEach(H, inputQubits);


        let iteration = (type == "min")
            ? GroverIterationMin(threshold, _, auxQubit, iterations)
            | GroverIterationMax(threshold, _, auxQubit, iterations);

        // Apply the iteration
        iteration(inputQubits);
        
        // Measure the qubits
        let results = MeasureEachZ(inputQubits);

        // Reset qubits
        ResetAll(inputQubits + [auxQubit]);

        // Convert results to integer index

        // Return the candidate index
        return results;
    }
export DurrHoyerAlgorithmProduction;

}