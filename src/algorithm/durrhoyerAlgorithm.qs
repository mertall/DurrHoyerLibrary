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

        // Convert the clause integer to an n-bit binary string and reverse it
        // to match qubit ordering (least significant bit first)
        let clauseBinary = ConvertToBinary(clause, n);

        // Apply X gates to qubits where the clause binary has '0'
        for index in 0 .. n - 1 {
            if (clauseBinary[index] == Zero) {
                X(clauseQubits[index]);
            }
        }

        // Apply a multi-controlled Z gate (phase flip)
        // Since Q# does not have a direct MCZ gate, we can implement it using
        // a multi-controlled X gate with an ancilla qubit or by using the
        // native Toffoli (CCNOT) gates for up to 2 controls.
        // For simplicity, we'll implement a phase flip using the MultiControlledX operation.

        // Note: As of my knowledge cutoff in September 2021, Q# does not have a built-in
        // MCX gate with a control state. You might need to use ancilla qubits for more
        // than two controls. Here, we'll assume n <= 3 for simplicity.

        Controlled X(clauseQubits[0..n-1], output);
        

        // Revert X gates to restore the original state of clause qubits
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

        // Convert the clause integer to an n-bit binary string and reverse it
        // to match qubit ordering (least significant bit first)
        let clauseBinary = ConvertToBinary(clause, n);

        // Apply X gates to qubits where the clause binary has '0'
        for index in 0 .. n - 1 {
            if (clauseBinary[index] == One) {
                X(clauseQubits[index]);
            }
        }

        // Apply a multi-controlled Z gate (phase flip)
        // Since Q# does not have a direct MCZ gate, we can implement it using
        // a multi-controlled X gate with an ancilla qubit or by using the
        // native Toffoli (CCNOT) gates for up to 2 controls.
        // For simplicity, we'll implement a phase flip using the MultiControlledX operation.

        // Note: As of my knowledge cutoff in September 2021, Q# does not have a built-in
        // MCX gate with a control state. You might need to use ancilla qubits for more
        // than two controls. Here, we'll assume n <= 3 for simplicity.

        Controlled X(clauseQubits[0..n-1], output);
        

        // Revert X gates to restore the original state of clause qubits
        for index in 0 .. n - 1 {
            if (clauseBinary[index] == One) {
                X(clauseQubits[index]);
            }
        }
    }
    // Diffusion operator (Grover's diffusion)
    operation DiffusionOperator(qubits : Qubit[]) : Unit {
        ApplyToEach(H, qubits);
        ApplyToEach(X, qubits);
        Controlled Z(qubits[0..Length(qubits) - 2], qubits[Length(qubits) - 1]);
        ApplyToEach(X, qubits);
        ApplyToEach(H, qubits);
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
    // operation DurrHoyerAlgorithmSimulation(list : Int[], nQubits : Int, type : String, candidate: Int, listSize : Int) : Int {
    //     mutable candidate = candidate;  // Random initial candidate

    //     use inputQubits = Qubit[nQubits] {
    //         use auxQubit = Qubit() {
    //             // Create a superposition of all states
    //             ApplyToEach(H, inputQubits);

    //             // Continue Grover search until no better candidate is found
    //             mutable betterCandidateFound = true;
    //             mutable iterationCount = 1; // Track the iteration count manually
    //             mutable optimalIterations = 5;
    //             mutable validIterations = 0;

    //             while (validIterations < optimalIterations) {
    //                 set betterCandidateFound = false;
    //                 let threshold = list[candidate];

    //                 // Define the comparison function based on the type
    //                 let comparison = type == "min" ? (x -> x < threshold) | (x -> x > threshold);

    //                 // Calculate M: the number of elements smaller than the current candidate (for min)
    //                 let M = CountElements(list, comparison);

    //                 // If there are no more elements smaller/larger, return the candidate
    //                 if (M == 0) {
    //                     Message("No more elements to compare, search complete.");
    //                     ResetAll(inputQubits + [auxQubit]);  // Ensure qubits are reset before returning
    //                     return candidate;
    //                 }

    //                 // Calculate the optimal number of Grover iterations
    //                 let N = Length(list);
    //                 let optimalIterations = Round((PI() / 4.0) * Sqrt(IntAsDouble(N) / IntAsDouble(M)));

    //                 // Perform Grover iterations for min or max
    //                 for i in 1..optimalIterations {
    //                     let groverIteration = (type=="min") ? GroverIterationMin | GroverIterationMax;
    //                     groverIteration(list[candidate], inputQubits, auxQubit);

    //                     // Measure qubits and convert to an integer index
    //                     mutable results = [];
    //                     for qubit in inputQubits {
    //                         let result = Measure([PauliZ], [qubit]);
    //                         set results += [result];

    //                         // Reset qubit if it is in the |1⟩ state
    //                         if (result == One) {
    //                             X(qubit);
    //                         }
    //                     }

    //                     let candidateIndex = ResultArrayAsInt(results);

    //                     // Check if the new candidate is valid and within bounds
    //                     if (candidateIndex >= 0 and candidateIndex < listSize) {
    //                         let candidateValue = list[candidateIndex];

    //                         // Update the candidate if a better one is found
    //                         if (type == "min" and candidateValue < list[candidate]) {
    //                             OracleLessThan(list[candidate], inputQubits, auxQubit); // Mark the last candidate
    //                             set candidate = candidateIndex;
    //                             set betterCandidateFound = true;
    //                         } elif (type == "max" and candidateValue > list[candidate]) {
    //                             OracleMoreThan(list[candidate], inputQubits, auxQubit); // Mark the last candidate
    //                             set candidate = candidateIndex;
    //                             set betterCandidateFound = true;
    //                         }
    //                         set validIterations += 1;

    //                         // Output intermediate results for debugging
    //                         Message($"Iteration {validIterations}: Measured index = {candidateIndex}, Value = {candidateValue}");
    //                     }
    //                     // Reset all qubits to |0⟩ before returning
    //                     ResetAll(inputQubits + [auxQubit]);

    //                 }

    //             }

    //             // Reset all qubits to |0⟩ before returning
    //             ResetAll(inputQubits + [auxQubit]);

    //             // Return the found minimum or maximum index
    //             return candidate;
    //         }
    //     }
    // }
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