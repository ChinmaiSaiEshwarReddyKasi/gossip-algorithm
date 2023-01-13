# DSOP Project 2 - Gossip Algorithm

**Introduction:**

In this report, we describe the performance of the Asynchronous Gossip and Push- Sum algorithms while modeling various topologies. In addition, we calculate the convergence time for various number of actors and give our findings for each ar- chitecture. For Gossip, the convergence happens when all nodes in the network have heard the rumor, and for Push-sum, when the node ratio changes by less than 10<sup>-10</sup>.

**Results:**

The results of our simulations on all topologies are presented below. For each sim- ulation, the number of actors/nodes is steadily raised, ranging from 10 to 10000 nodes. In addition, a simulation is performed by initializing and running the two algorithms on all topologies.

**Topologies:**

**Line Topology:**

A basic line topology depicts a series of nodes linked in a line. In the case of Gossip and Pushsum, the line topology performed the poorest. This finding is not surprising in theory. Because each node only has one or two connections, the messages propagate linearly, with each node waiting for its messages to arrive until the last node is reached and convergence occurs.

**Fully Connected Topology:**

A completely linked network is one in which all nodes are interconnected.For our simulations, this design often performed the best across all actor sizes.

**2D and Imperfect 3D:**

In case of 2D, neighbor processes are arranged on a 2D square grid. If the number of nodes is a perfect square we take that value else we round it to nearest integer and then place the remaining neighbors on the 2D grid. The maximum number of neighbors is four, while the lowest is two.

Unlike 2D, in imperfect 3D each Neighbor has one extra random node as a neighbor, resulting in maximum and minimum neighbors of 4 and 3, respectively.

**How to Execute:**

\>c(project2).

\>project2:main(NumNodes, Algorithm , Topology)

NumNodes = value of Nodes to be processed

Algorithm = ”gossip” or ”pushsum”(should be given as string in quotes) Topology = ”full” or ”line” or ”2d” or ”imp3d”

**Project Questions:**

What is working:

- For line, full, 2d, and imp2d topologies, gossip and the push-sum method are implemented and working as expected.
- Thetemporalorderofconvergenceforgossipandpush-sumisthesame. The sequence is as: full < imp3d < 2d < line

Largest network for each topology and algorithm:

- Gossip - 10000 nodes
- Push Sum - 1000 nodes
