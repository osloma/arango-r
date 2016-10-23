library(igraph)
library(httr)
library(visNetwork)

#################------Functions to extract and structure data -------------##########

#URL to run for extracting the data on database Finance in ArangoDB
urlCursor <- "http://arangodb:8529/_db/ProductDatabase/_api/cursor"

#Security to authenticate in ArangoDB
myuser <- "XXXX"
mypass <- "XXXX"

#Extract Products from ArangoDB
extractProducts <- function(urlCursor){
  queryProductAQL <- "for p in Product return p"
  result <- POST(url = urlCursor, body = paste('{"query":"', queryProductAQL, '", "count":true}'), authenticate(user = myuser, password = mypass))
  resulta <- content(result, "parsed", "application/json")
  n <- resulta[1]
  s <- n$result
  productsDF <- data.frame(id=integer(), type=character(), numberOfShares=integer(), rev=integer(), stringsAsFactors=FALSE)
  
  #Extracts all the node names and place on a single list
  for(x in 1:length(s)){
    id <- s[x][[1]]$'_id'
    rev <- s[x][[1]]$'_rev'
    type <- if(is.character(s[x][[1]]$'type')) s[x][[1]]$'type' else 'Not Specified'
    numberOfShares <- if(is.integer(s[x][[1]]$'numberOfShares')) s[x][[1]]$'numberOfShares' else 0
    productsDF[nrow(productsDF) + 1, ] <- c(id, type, numberOfShares, rev)
  }
  productsDF$group <- productsDF$type
  productsDF
}

#Extract Relations from ArangoDB
extractProductsRel <- function(urlCursor){
  queryProductRelAQL <- "for p in ProductRelations return p"
  result <- POST(url = urlCursor, body = paste('{"query":"', queryProductRelAQL, '"}'), authenticate(user = myuser, password = mypass))
  resulta <- content(result, "parsed", "application/json")
  n <- resulta[1]
  s <- n$result
  productsRelDF <- data.frame(id=integer(), key=character(), from=character(), to=character(), percentage=integer(), color=character(), stringsAsFactors=FALSE)
  
  #Extracts all the rel names and place on a single list
  for(x in 1:length(s)){
    id <- s[x][[1]]$'_id'
    rev <- s[x][[1]]$'_key'
    from <- s[x][[1]]$'_from'
    to <- s[x][[1]]$'_to'
    percentage <- if(is.integer(s[x][[1]]$'percentage')) s[x][[1]]$'percentage' else 0
    color <- cut(percentage, breaks = c(-Inf, 50, 75, 101), labels = c('red', 'orange', 'green'))
    productsRelDF[nrow(productsRelDF) + 1, ] <- c(id, rev, from, to, percentage, color)
  }
  productsRelDF
}


#Create an igraph graph starting from products and their relations
#Also it adds attributes to the vertex and edges from initial dataframes
setGraph <- function(product, productRel){
  df <- productRel[c("from", "to")]
  g <- graph.data.frame(df)
  
  #Add vertext properties
  V(g)$id <- product$id
  V(g)$type <- product$type
  V(g)$group <- product$group
  V(g)$numberOfShares <- product$numberOfShares
  
  #Add edges properties
  E(g)$percentage <- productRel$percentage
  E(g)$color <- productRel$color
  
  g
}

productNodes <- extractProducts(urlCursor)
productEdges <- extractProductsRel(urlCursor)


productGraph <- setGraph(productNodes, productEdges)

############---------------Network measures --------------------------###################

assortativity.degree(productGraph)

closeness(graph = productGraph, normalized = TRUE)

vertex.connectivity(graph = productGraph)

laplacian <- laplacian_matrix(graph = productGraph, sparse = FALSE)

print(laplacian)

############---------------Network simplification ---------------------###################

#Apply a PCA to schrink the network so the variance 
pcaGraph <- princomp(laplacian)
summary(pcaGraph)
pcaGraph$scores
pcaGraph$sdev
pcaGraph$loadings

############---------------Network Visualization ----------------------###################

plot(productGraph, layout = layout.davidson.harel, edge.arrow.size = .4)

visNetwork(nodes = productNodes, edges = productEdges, height = "500px", width = "500px", smooth = FALSE)  %>%
  visGroups(groupname = "Currency", shape = "icon", 
            icon = list(code = "f0d6", size = 75)) %>%
  visGroups(groupname = "MutualFund", shape = "icon", 
            icon = list(code = "f0c0", color = "red")) %>%
  visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T)) %>%
  visClusteringByGroup(groups = c("Derivative")) %>%
  visLegend() %>%
  addFontAwesome()

############--------------Network communities--------------------------###################

#Standard clustering to see possible clusters only considering the configuration of the network
edge.betweenness.community(graph = productGraph, edge.betweenness = TRUE)

#For hierarchical clustering, calculate the distance between nodes first. 
#That can be done using multiple metrics (below two samples as euclidean or manhattan
laplacian_distance <-dist(x = laplacian, method = "euclidean")
#laplacian_distance <-dist(x = laplacian, method = "manhattan")

#Obtain the tree based on hierarchical clustering and plot
hier_cluster <- hclust(laplacian_distance)
plot(hier_cluster)

#draw a dendogram with red borders around 5 clusters
rect.hclust(hier_cluster, border = "red", k = 5)
