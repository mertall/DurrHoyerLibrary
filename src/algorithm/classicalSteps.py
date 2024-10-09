import matplotlib.pyplot as plt
import math
import random

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

def run_durr_hoyer_algorithm(list_data, type_search="min", max_iterations=10):
    """
    Executes the Dürr-Høyer algorithm and simulates the number of iterations.
    Terminates once the minimum or maximum value is found.

    :param list_data: List of integers to search.
    :param type_search: "min" (for finding the minimum value) or "max" (for finding the maximum value).
    :param max_iterations: Maximum number of iterations.
    :return: The found minimum or maximum value from the list.
    """
    if type_search not in ["min", "max"]:
        raise ValueError("type_search must be either 'min' or 'max'.")

    N = len(list_data)
    if N == 0:
        raise ValueError("The list is empty.")

    # Initialize a random candidate from the list
    candidate_index = random.randint(0, N - 1)
    candidate_value = list_data[candidate_index]
    
    if type_search == "min":
        target_value = min(list_data)
    else:
        target_value = max(list_data)
    
    iteration = 0

    while iteration < max_iterations:
        iteration += 1
        new_candidate_index = random.randint(0, N - 1)  # Simulating randomness
        new_candidate_value = list_data[new_candidate_index]

        if (type_search == "min" and new_candidate_value < candidate_value) or \
           (type_search == "max" and new_candidate_value > candidate_value):
            candidate_index = new_candidate_index
            candidate_value = new_candidate_value

        # If the target value is found, terminate early
        if candidate_value == target_value:
            break

    return candidate_value

def run_shots_with_varying_shots(max_shots, max_iterations, type_search="min", trials=100):
    """
    Runs the Dürr-Høyer algorithm for varying numbers of shots and calculates
    the average success rate over multiple trials for each number of shots.

    :param max_shots: Maximum number of shots to run.
    :param max_iterations: Maximum number of iterations in each shot.
    :param type_search: Either "min" or "max" depending on whether to search for the minimum or maximum.
    :param trials: Number of trials to run for each number of shots.
    :return: Two lists: number of shots and corresponding average success rates.
    """
    # Parameters for the sample list
    N = 6  # Size of the list
    lower = 0
    upper = 5

    # Lists to store number of shots and corresponding average success rates
    shots_data = []
    avg_success_rate_data = []

    # Run for different numbers of shots
    for shot_count in range(1, max_shots + 1):
        total_success = 0
        
        # Run multiple trials
        for _ in range(trials):
            # Generate a new sample list for each trial
            sample_list = generate_sample_list(N, lower, upper)
            
            if type_search == "min":
                target_value = min(sample_list)
            else:
                target_value = max(sample_list)
                
            found_target = False

            # Run the algorithm for the given number of shots
            for shot in range(shot_count):
                found_value = run_durr_hoyer_algorithm(sample_list, type_search=type_search, max_iterations=max_iterations)
                if found_value == target_value:
                    found_target = True
                    break  # If found at least once, no need to continue this set of shots

            # If target value (min or max) was found at least once, success
            if found_target:
                total_success += 1

        # Calculate average success rate over all trials
        avg_success_rate = (total_success / trials) * 100
        shots_data.append(shot_count)
        avg_success_rate_data.append(avg_success_rate)
        print(f"Shots: {shot_count}, Average Success Rate: {avg_success_rate:.2f}%")

    return shots_data, avg_success_rate_data

# Run the simulation for varying numbers of shots for both min and max
max_iterations = int((math.pi / 2) * math.sqrt(6))
max_shots = 6  # Maximum number of shots to test
trials = 100  # Number of trials for each number of shots

# Run for finding the minimum
print("### Running for Minimum ###")
shots_data_min, avg_success_rate_data_min = run_shots_with_varying_shots(max_shots=max_shots, max_iterations=max_iterations, type_search="min", trials=trials)

# Run for finding the maximum
print("\n### Running for Maximum ###")
shots_data_max, avg_success_rate_data_max = run_shots_with_varying_shots(max_shots=max_shots, max_iterations=max_iterations, type_search="max", trials=trials)

# Plotting the results for Minimum and Maximum
plt.figure(figsize=(10, 6))
plt.plot(shots_data_min, avg_success_rate_data_min, marker='o', linestyle='-', color='b', label='Minimum')
plt.plot(shots_data_max, avg_success_rate_data_max, marker='o', linestyle='--', color='r', label='Maximum')
plt.title('Average Success Rate vs Number of Shots (Dürr-Høyer Algorithm)')
plt.xlabel('Number of Shots')
plt.ylabel('Average Success Rate (%)')
plt.grid(True)
plt.legend()
plt.show()
