Arango HTTP R
============

## Update 
This project uses HTTP connection to reach to ArangoDB. If you want to use an R driver to connect there, feel free to have a look at https://gitlab.com/krpack/arango-driver


# Introduction

This project contains sample code to extract data from ArangoDB into R to integrate with igraph library. After extracting data applies:
- Different metrics on the igraph graph already created
- Dimensionality reduction to get important nodes and network
- Network plotting using two different R libraries
- Community detection using network configuration

# Details on the project

Arango DB is an Open Source Multimodel Database. There are very few samples on how to integrate it with R, so this will help the Community on how to use both.

In this project, data is stored as a graph in ArangoDB and queried using HTTP cursors that Arango provides, to create an igraph graph in R. 
The main advantage of using igraph rather than the built in functionality that Arango provides natively is that there are multiple functions that can be used already in R applied on the graph (rather that trying to create them in ArangoDB). 
The HTTP cursors can be used to do any operation on the ArangoDB collections, but here we use it only for getting the data (for more info see ArangoDB [documentation] (https://docs.arangodb.com/3.0/HTTP/)

The code in R contains a small set of all possible metrics and operations that can be performed using igraph, so feel free to extend this code with your favorites ;)

Metrics calculated on the sample network are:
- [Assortativity] (https://en.wikipedia.org/wiki/Assortativity)
- [Closeness] (https://en.wikipedia.org/wiki/Centrality#Closeness_centrality)
- [Laplacian matrix] (https://en.wikipedia.org/wiki/Laplacian_matrix)

To simplify the network a PCA algorithm is applied on top of the obtained laplacian matrix. 
Then we see that two of the nodes add no variance to the global network, so we can take the rest of them securely

For network visualization two options are shown:
- igraph plot library
- visNetwork library 

In case of community detection, two samples are done:
- standard community based on betweenness 
- based on distances on nodes (two samples are shown), calculate hierarchical clustering for 5 of them

The first version of the code is located on file ProductAnalysis.R
