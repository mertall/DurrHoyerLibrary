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
/// Oracle that marks elements less than the threshold using a multi-bit comparator
/// Excluded Indices is a list of 0 and 1s classicaly, converted to qubits of 0 and 1, where N is length of inputQubits
    operation OracleLessThan(
        threshold : Int, 
        inputQubits : Qubit[], 
        auxQubit : Qubit,
        excludedIndices : Int[] 
    ) : Unit is Adj + Ctl {
        let n = Length(inputQubits);
        let thresholdBits = ConvertToBinary(threshold, n);

        // Ancilla qubit to track if input < threshold
        use ancilla = Qubit();

        // Initialize ancilla to |0>
        Reset(ancilla);

        // Iterate through each bit from MSB to LSB
        for i in n - 1 .. -1 .. 0 {
            let inputBit = inputQubits[i];
            let thresholdBit = thresholdBits[i];

            // Compare inputBit and thresholdBit
            if (thresholdBit == Zero) {
                // If threshold bit is 0
                // If input bit is 1, then input > threshold at this bit
                CNOT(inputBit, ancilla);
            } elif (thresholdBit == One) {
                // If threshold bit is 1
                // If input bit is 0, then input < threshold at this bit
                CNOT(inputBit, ancilla);
                X(ancilla); // Invert to mark less than
            }
        }

        // Apply phase flip if ancilla indicates input < threshold
        CZ(ancilla, auxQubit);

        // Undo operations (if any) and reset ancilla
        Reset(ancilla);

    }
    
    /// Oracle that marks elements less than the threshold using a multi-bit comparator
/// Excluded Indices is a list of 0 and 1s classicaly, converted to qubits of 0 and 1, where N is length of inputQubits
    operation OracleMoreThan(
        threshold : Int, 
        inputQubits : Qubit[], 
        auxQubit : Qubit,
        excludedIndices : Int[] 
    ) : Unit is Adj + Ctl {
        let n = Length(inputQubits);
        let thresholdBits = ConvertToBinary(threshold, n);

        // Ancilla qubit to track if input < threshold
        use ancilla = Qubit();

        // Initialize ancilla to |0>
        Reset(ancilla);

        // Iterate through each bit from MSB to LSB
        for i in n - 1 .. -1 .. 0 {
            let inputBit = inputQubits[i];
            let thresholdBit = thresholdBits[i];

            // Compare inputBit and thresholdBit
            if (thresholdBit == Zero) {
                // If threshold bit is 0
                // If input bit is 1, then input > threshold at this bit
                CNOT(inputBit, ancilla);
                X(ancilla); // Invert to mark less than
            } elif (thresholdBit == One) {
                // If threshold bit is 1
                // If input bit is 0, then input < threshold at this bit
                CNOT(inputBit, ancilla);
            }
        }

        // Apply phase flip if ancilla indicates input < threshold
        CZ(ancilla, auxQubit);

        // Undo operations (if any) and reset ancilla
        Reset(ancilla);

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
    operation GroverIterationMin(threshold : Int, inputQubits : Qubit[], auxQubit : Qubit, excludedIndices : Int[]) : Unit {
        OracleLessThan(threshold, inputQubits, auxQubit, excludedIndices);
        DiffusionOperator(inputQubits);
    }

    // Grover iteration with the oracle and diffusion operator for max
    operation GroverIterationMax(threshold : Int, inputQubits : Qubit[], auxQubit : Qubit,excludedIndices : Int[]) : Unit {
        OracleMoreThan(threshold, inputQubits, auxQubit,excludedIndices);
        DiffusionOperator(inputQubits);
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
    excludedValues : Int[]
    ) : Result[]{
        // Initial candidate (passed as parameter)
        let threshold = list[candidate];

        use inputQubits = Qubit[nQubits];
        use auxQubit = Qubit();

        // Prepare the superposition state
        ApplyToEach(H, inputQubits);


        let iteration = (type == "min")
            ? GroverIterationMin(threshold, _, auxQubit, excludedValues)
            | GroverIterationMax(threshold, _, auxQubit, excludedValues);


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