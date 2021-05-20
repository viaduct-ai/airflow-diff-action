from airflow.models import DagBag
from collections import defaultdict
import sys


def dump_dags(outfile):
    bag = DagBag()
    for dag_id in sorted(bag.dag_ids):
        dag = bag.get_dag(dag_id)
        outfile.write(f'== {dag_id} ==\n\n')

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
        print('Usage: dump_dags.py <output filename>')
        sys.exit(1)
    with open(sys.argv[1], 'w') as outfile:
        dump_dags(outfile)
