 namespace tests{
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Random;
    open Microsoft.Quantum.Core;   
    open Microsoft.Quantum.Diagnostics;
    open durrHoyerAlgorithm;
    
    function MaxIntArray(arr : Int[]) : Int {
    mutable max = arr[0];
    for i in arr[1 .. Length(arr) - 1] {
        if (i > max) {
                set max = i;
        }
    }
    return max;
    }
    operation RunDurrHoyerMinimumUnitTests() : Unit {
        let testLists = [
            [5, 3, 1, 2, 4],
            [6, 5, 4, 3, 1],
            [7, 5, 6, 1, 2]
        ];

        for list in testLists {
            let maxValue = MaxIntArray(list);
            let double : Double = IntAsDouble(maxValue+1);
            let log : Double = Log(double)/Log(2.0);
            let nQubits = Ceiling(log);
            let minIndex : Int = DurrHoyerFinding(list, nQubits, "min");

            // Classical steps and Grover's steps for comparison
            let classicalSteps = Length(list);
            
            // Print results
            Message($"List: {list}");
            Message($"Minimum element found at index {minIndex} with value {list[minIndex]}");         
        }
    }

    operation RunDurrHoyerMaximumUnitTests() : Unit {
        let testLists = [
            [5, 3, 1, 2, 4],
            [6, 5, 4, 3, 1],
            [7, 5, 6, 1, 2]
        ];

        for list in testLists {
            let maxValue = MaxIntArray(list);
            let double : Double = IntAsDouble(maxValue+1);
            let log : Double = Log(double)/Log(2.0);
            let nQubits = Ceiling(log);
            let maxIndex : Int = DurrHoyerFinding(list, nQubits, "max");

            // Classical steps and Grover's steps for comparison
            let classicalSteps = Length(list);
            
            // Print results
            Message($"List: {list}");
            Message($"Maximum element found at index {maxIndex} with value {list[maxIndex]}");
        }
    }
    @EntryPoint()
    operation RunTests() : Unit {
        RunDurrHoyerMinimumUnitTests();
        RunDurrHoyerMaximumUnitTests();
    }
    export RunDurrHoyerMinimumUnitTests;
    export RunDurrHoyerMaximumUnitTests;
 }