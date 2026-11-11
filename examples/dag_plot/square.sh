#!/bin/bash
# "Computation" script that squares its input, then writes `N, N**2` to an output file
NUM=$1
echo ${NUM},$((NUM ** 2)) > ${NUM}_squared.txt
