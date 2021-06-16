from airflow.models import DagBag
from collections import defaultdict
import os, sys


def dump_dags(output_base_path):
    os.makedirs(output_base_path, exist_ok=True)
    bag = DagBag()
    assert not bag.import_errors
    for dag_id in sorted(bag.dag_ids):
        dag = bag.get_dag(dag_id)

        with open(os.path.join(output_base_path, dag_id), 'w') as outfile:
            adj = defaultdict(list)  # Adjacency list of DAG.
            for task in dag.tasks:
                for upstream_task_id in task.upstream_task_ids:
                    adj[upstream_task_id].append(task.task_id)

            for task_id in sorted(dag.task_ids):
                task = dag.get_task(task_id)
                outfile.write(f'{task_id}\n')
                for child_task_id in sorted(adj[task_id]):
                    outfile.write(f' -> {child_task_id}\n')
                outfile.write('\n')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: dump_dags.py <output base path>')
        sys.exit(1)
    dump_dags(sys.argv[1])
