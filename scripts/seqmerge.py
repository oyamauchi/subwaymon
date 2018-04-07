#!/usr/bin/env python3

from typing import *

T = TypeVar('T')

def seqmerge(seqs: Iterable[Sequence[T]]) -> List[T]:
    return SequenceMerge(seqs).execute()


class SequenceMerge(Generic[T]):
    """Merges many sequences into a single one with a consistent ordering.

    The idea is to combine several linear sequences into a single DAG. We then
    do a depth-first-search-based topological sort on that DAG.
    """

    def __init__(self, seqs: Iterable[Sequence[T]]) -> None:
        self._seqs = seqs

    def execute(self) -> List[T]:
        # Build up the DAG, represented as adjacency lists
        adjacency: Dict[T, List[T]] = {}
        nodes: Set[T] = set()
        nodes_with_in_edge: Set[T] = set()

        for seq in self._seqs:
            nodes.update(seq)

            for i in range(len(seq) - 1):
                here = seq[i]
                if here not in adjacency:
                    adjacency[here] = []
                adjacency[here].append(seq[i + 1])
                nodes_with_in_edge.add(seq[i + 1])

            if seq[-1] not in adjacency:
                adjacency[seq[-1]] = []

        # Sort adjacency lists so output is consistent across runs
        for v in adjacency.values():
            v.sort()

        self._adjacency = adjacency
        self._visiting: Set[T] = set()
        self._done: Set[T] = set()
        self._result: List[T] = []

        # Now a topological sort using depth-first search. This will keep runs
        # of adjacent stops together, despite any branching. However, runs of
        # adjacent stops can still get split up if we start the DFS in the
        # middle of one, so we start at the nodes with no incoming edge.
        sources = nodes.difference(nodes_with_in_edge)

        # Sort the sources so the output is consistent across runs.
        for node in sorted(sources):
            self._visit(node)

        assert(len(self._done) == len(nodes))

        # Nodes are appended by _visit(), so reverse to get the original order
        self._result.reverse()
        return self._result

    def _visit(self, node: T) -> None:
        if node in self._done:
            return
        if node in self._visiting:
            raise Exception("cycle!")

        self._visiting.add(node)
        for neighbor in self._adjacency[node]:
            self._visit(neighbor)
        self._visiting.remove(node)
        self._done.add(node)
        self._result.append(node)
