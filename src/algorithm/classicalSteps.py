import qsharp
from qsharp import Result
import math
import random
from quantumbackendDH import QuantumBackendDH

# Initialize the Quantum Backend
dh_backend = QuantumBackendDH()

def result_array_as_int(results):
    """
    Converts an array of Q# Results to an integer.
    Assumes the least significant bit is at index 0.
    
    :param results: List of Result enums.
    :return: Integer representation of the binary input.
    """
    value = 0
    for i, res in enumerate(results):
        if res == Result.One:
            value |= (1 << i)
    return value

def run_durr_hoyer_algorithm(list_data, type_search="min"):
    """
    Executes the Dürr-Høyer algorithm to find the minimum or maximum element in the list
    using a fixed number of steps: 22.5 * sqrt(N) + 1.4 * log2(N).
    
    :param list_data: List of integers to search.
    :param type_search: "min" or "max".
    :return: The found minimum or maximum value from the list.
    """
    if type_search not in ["min", "max"]:
        raise ValueError("type_search must be either 'min' or 'max'.")

    N = len(list_data)
    if N == 0:
        raise ValueError("The list is empty.")

    # Calculate the number of qubits required to represent all indices
    n_qubits = math.ceil(math.log2(N))
    if 2**n_qubits < N:
        print(f"Adjusting number of qubits from {n_qubits} to {n_qubits + 1} to accommodate all indices.")
        n_qubits += 1

    # Calculate the number of steps based on the given formula
    # Formula for tight bounds: (pi/4) * sqrt(N)
    num_steps = (math.pi/4) * math.sqrt(N)
    num_steps = math.ceil(num_steps)  # Round up to the nearest integer
    print(f"Calculated number of steps: {num_steps} (pi/4) * sqrt(N)  ")

    # Initialize candidate randomly
    candidate_index = random.randint(0, N - 1)
    candidate = list_data[candidate_index]
    print(f"Initial candidate: Index = {candidate_index}, Value = {candidate}")

    # Execute the Dürr-Høyer algorithm via Q# backend
    measured_result = dh_backend.execute_dh(
        optimal_iterations=num_steps,
        input_list=list_data,
        nqubits=n_qubits,
        random_index=candidate_index,
        type=type_search,
        list_size=N
    )
    print(f"Measured Result (Binary): {measured_result}")

    # Convert the binary result to an integer index
    new_candidate_index = result_array_as_int(measured_result)
    print(f"Measured Candidate Index: {new_candidate_index}")

    # Validate the measured index
    if new_candidate_index < 0 or new_candidate_index >= N:
        print("Measured index out of bounds. Skipping update.")
        # Return the current candidate as no valid update occurred
        return candidate

    new_candidate = list_data[new_candidate_index]
    print(f"Measured Candidate Value: {new_candidate}")

    # Update the candidate if a better one is found
    if (type_search == "min" and new_candidate < candidate) or (type_search == "max" and new_candidate > candidate):
        print(f"Updating candidate from index {candidate_index} to {new_candidate_index}")
        candidate_index = new_candidate_index
        candidate = new_candidate
    else:
        print("No better candidate found in this step.")

    print(f"\nFinal candidate after {num_steps} steps: Index = {candidate_index}, Value = {candidate}")
    return candidate

def generate_sample_list(N, lower=0, upper=10):
    """
    Generates a sample list of N unique integers within the specified range.

    :param N: Number of elements in the list.
    :param lower: Lower bound for integer values.
    :param upper: Upper bound for integer values.
    :return: List of unique integers.
    """
    if upper - lower + 1 < N:
        raise ValueError("Range is too small to generate unique elements.")

    return random.sample(range(lower, upper + 1), N)

def run_shots(shots=10):
    """
    Runs the Dürr-Høyer algorithm multiple times and calculates the accuracy of finding
    the correct minimum and maximum values.
    
    :param shots: Number of shots.
    """
    # Parameters for the sample list
    N = 10  # Size of the list
    lower = 0
    upper = 10

    # Generate a single sample list for all shots
    sample_list = generate_sample_list(N, lower, upper)
    print(f"List to search (N={N}): {sample_list}")

    # Determine the actual min and max using Python's built-in functions
    actual_min = min(sample_list)
    actual_max = max(sample_list)
    print(f"Actual Minimum: {actual_min}")
    print(f"Actual Maximum: {actual_max}\n")

    # Counters for correct results
    correct_min = 0
    correct_max = 0

    for shot in range(1, shots + 1):
        print(f"--- Shot {shot} ---")
        
        # Run min search
        found_min = run_durr_hoyer_algorithm(sample_list, type_search="min")
        if found_min == actual_min:
            correct_min += 1
            print("Min search successful.\n")
        else:
            print(f"Min search failed. Found {found_min}, Expected {actual_min}\n")
        
        # Run max search
        found_max = run_durr_hoyer_algorithm(sample_list, type_search="max")
        if found_max == actual_max:
            correct_max += 1
            print("Max search successful.\n")
        else:
            print(f"Max search failed. Found {found_max}, Expected {actual_max}\n")

    # Calculate success rates
    min_success_rate = (correct_min / shots) * 100
    max_success_rate = (correct_max / shots) * 100

    print(f"--- Shots Results ---")
    print(f"Total shots: {shots}")
    print(f"Minimum Search: {correct_min} successes out of {shots} ({min_success_rate:.2f}%)")
    print(f"Maximum Search: {correct_max} successes out of {shots} ({max_success_rate:.2f}%)")

if __name__ == "__main__":
    # Run 100 shots and calculate the average success rates
    run_shots(shots=100)
