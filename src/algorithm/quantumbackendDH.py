import qsharp
import azure.quantum
import math
import random

class QuantumBackendDH():
    def __init__(self):
        self.workspace = azure.quantum.Workspace(
            resource_id = "/subscriptions/d8ddd235-82ee-4455-9a76-7206f23c32f4/resourceGroups/AzureQuantum/providers/Microsoft.Quantum/Workspaces/algotestmin",
            location = "eastus"
        )

    
    def execute_dh(self,iterations, input_list, nqubits, type, list_size, random_index):
        random_index = random.randint(0,list_size-1)

        input_params = {
            "list": input_list,
            "nQubits": nqubits,
            "type": type,  # or "max"
            "candidate": random_index,
            "listSize": list_size,
            "iterations": iterations
        }

        inputs = ", ".join([
            str(input_params["list"]),
            str(input_params["nQubits"]),
            f'"{input_params["type"]}"',
            str(input_params["candidate"]),
            str(input_params["listSize"]),
            str(input_params["iterations"])
        ])

        # MyTargets = self.workspace.get_targets()

        # for x in MyTargets:
        #     print(x)
        qsharp.init(project_root = '../DurrHoyerLibrary/', target_profile=qsharp.TargetProfile.Base)
        MyProgram = qsharp.compile("durrhoyerAlgorithm.DurrHoyerAlgorithmProduction("+inputs+")")


        MyTarget = self.workspace.get_targets("rigetti.qpu.ankaa-9q-3")

        job = MyTarget.submit(MyProgram, "MyPythonJob", shots=1)
        results = job.get_results()
        print("\nResults: ", results)
        return results
