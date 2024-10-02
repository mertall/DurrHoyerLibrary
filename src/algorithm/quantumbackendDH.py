import qsharp
import azure.quantum
import math
import random
class QuantumBackendDH():
    def __init__(self):
        self.workspace = azure.quantum.Workspace(
            resource_id = "/subscriptions/3238cc54-1cd6-45c7-9d38-171cc490d18c/resourceGroups/AzureQuantum/providers/Microsoft.Quantum/Workspaces/durrhoyersim",
            location = "eastus"
        )

    
    def execute_dh(self,optimal_iterations, input_list, nqubits, type, list_size, random_index):
        random_index = random.randint(0,list_size-1)

        input_params = {
            "list": input_list,
            "nQubits": nqubits,
            "type": type,  # or "max"
            "candidate": random_index,
            "listSize": list_size,
            "optimalIterations": optimal_iterations
        }

        inputs = ", ".join([
            str(input_params["list"]),
            str(input_params["nQubits"]),
            f'"{input_params["type"]}"',
            str(input_params["candidate"]),
            str(input_params["listSize"]),
            str(input_params["optimalIterations"])
        ])
        MyTargets = self.workspace.get_targets()

        for x in MyTargets:
            print(x)
        qsharp.init(project_root = '../DurrHoyerLibrary/', target_profile=qsharp.TargetProfile.Base)
        MyProgram = qsharp.compile("durrhoyerAlgorithm.DurrHoyerAlgorithmProduction("+inputs+")")


        MyTarget = self.workspace.get_targets("ionq.qpu.aria-1")

        job = MyTarget.submit(MyProgram, "MyPythonJob", shots=1)
        results = job.get_results(timeout_secs=3600)
        print("\nResults: ", results)
        return results
