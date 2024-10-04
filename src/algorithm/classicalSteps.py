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

def count_better_candidates(list_data, candidate_value, type_search):
    """
    Counts the number of elements in the list that are better than the candidate value.
    
    :param list_data: List of integers to search.
    :param candidate_value: Current candidate value.
    :param type_search: "min" or "max".
    :return: Number of better candidates (M).
    """
    if type_search == "min":
        return sum(1 for value in list_data if value < candidate_value)
    elif type_search == "max":
        return sum(1 for value in list_data if value > candidate_value)
    else:
        raise ValueError("type_search must be either 'min' or 'max'.")

def run_durr_hoyer_algorithm(list_data, type_search="min"):
    """
    Executes the Dürr-Høyer algorithm to find the minimum or maximum element in the list.
    Manages iterations in Python, updating the excluded values after each iteration.
    
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
    if 2 ** n_qubits < N:
        print(f"Adjusting number of qubits from {n_qubits} to {n_qubits + 1} to accommodate all indices.")
        n_qubits += 1

    # Initialize candidate randomly
    candidate_index = random.randint(0, N - 1)
    candidate_value = list_data[candidate_index]
    print(f"Initial candidate: Index = {candidate_index}, Value = {candidate_value}")

    # Initialize the list of excluded values with the initial candidate index
    excluded_values = [candidate_index]

    # Initialize bit_list with zeros
    bit_list = [0] * N

    iteration = 0
    while True:
        iteration += 1
        print(f"\n--- Iteration {iteration} ---")
        # Count the number of better candidates (M)
        M = count_better_candidates(list_data, candidate_value, type_search)
        print(f"Number of better candidates (M): {M}")

        # If no better candidates, return the current candidate
        if M == 0:
            print("No better candidates found. Algorithm terminates.")
            break

        # Calculate the optimal number of iterations (k)
        k = int(round((math.pi / 4) * math.sqrt(N / M)))
        print(f"Calculated optimal iterations (k): {k}")

        # Execute the Dürr-Høyer algorithm via Q# backend
        measured_result = dh_backend.execute_dh(
            input_list=list_data,
            nqubits=n_qubits,
            random_index=candidate_index,
            type=type_search,
            list_size=N,
            excluded_values=excluded_values
        )
        print(f"Measured Result (Binary): {measured_result}")

        # Convert the binary result to an integer index
        new_candidate_index = result_array_as_int(measured_result)
        print(f"Measured Candidate Index: {new_candidate_index}")

        # Validate the measured index
        if new_candidate_index < 0 or new_candidate_index >= N:
            print("Measured index out of bounds. Skipping update.")
            break  # Exit the loop as no valid update occurred

        new_candidate_value = list_data[new_candidate_index]
        print(f"Measured Candidate Value: {new_candidate_value}")

        # Update the candidate if a better one is found
        better_candidate_found = False
        if (type_search == "min" and new_candidate_value < candidate_value):
            print(f"Updating candidate from index {candidate_index} to {new_candidate_index}")
            candidate_index = new_candidate_index
            candidate_value = new_candidate_value
            better_candidate_found = True
        elif (type_search == "max" and new_candidate_value > candidate_value):
            print(f"Updating candidate from index {candidate_index} to {new_candidate_index}")
            candidate_index = new_candidate_index
            candidate_value = new_candidate_value
            better_candidate_found = True
        else:
            print("No better candidate found in this iteration.")
            # Add the measured index to the excluded values
            if new_candidate_index not in excluded_values:
                excluded_values.append(new_candidate_index)
            break  # Exit the loop as no better candidate was found

        # Update excluded values
        if candidate_index not in excluded_values:
            excluded_values.append(candidate_index)

        # Update bit_list based on comparison with candidate
        for idx, value in enumerate(list_data):
            if type_search == "min":
                if value < candidate_value:
                    bit_list[idx] = 1  # Flip bit from 0 to 1
            elif type_search == "max":
                if value > candidate_value:
                    bit_list[idx] = 1  # Flip bit from 0 to 1

        print(f"Excluded Values: {excluded_values}")
        print(f"Bit List: {bit_list}")

        # Continue iterating if a better candidate was found
        if not better_candidate_found:
            print("No better candidate found. Algorithm terminates.")
            break

    print(f"\nFinal candidate after {iteration} iterations: Index = {candidate_index}, Value = {candidate_value}")
    return candidate_value

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
    N = 7  # Size of the list
    lower = 0
    upper = 100

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
        print(f"\n=== Shot {shot} ===")

        # Run min search
        print("\n--- Minimum Search ---")
        found_min = run_durr_hoyer_algorithm(sample_list, type_search="min")
        if found_min == actual_min:
            correct_min += 1
            print("Min search successful.")
        else:
            print(f"Min search failed. Found {found_min}, Expected {actual_min}")

        # Run max search
        print("\n--- Maximum Search ---")
        found_max = run_durr_hoyer_algorithm(sample_list, type_search="max")
        if found_max == actual_max:
            correct_max += 1
            print("Max search successful.")
        else:
            print(f"Max search failed. Found {found_max}, Expected {actual_max}")

    # Calculate success rates
    min_success_rate = (correct_min / shots) * 100
    max_success_rate = (correct_max / shots) * 100

    print(f"\n--- Shots Results ---")
    print(f"Total shots: {shots}")
    print(f"Minimum Search: {correct_min} successes out of {shots} ({min_success_rate:.2f}%)")
    print(f"Maximum Search: {correct_max} successes out of {shots} ({max_success_rate:.2f}%)")

if __name__ == "__main__":
    # Run the shots
    run_shots(shots=10)
