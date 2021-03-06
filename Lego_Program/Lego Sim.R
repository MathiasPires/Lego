#########################
# Niche Evolution Model #
#########################

rm(list=c(ls()))


source("rstring.r")
source("insertRow.r")
source("string.similarity.r")

str.length <- 10
max.ab <- 1000
t.term <- 100
innov.rate <- 5

####################################
#Initial conditions (t = 1)
####################################

#Global properties
niche.space <- numeric(t.term)
sp.richness <- numeric(t.term)
avg.complexity <- numeric(t.term)

#Vector of species
a <- numeric()
a.ab <- numeric()
#List of coproducts
b <- list()
b.ab <- list()
#List of unique coproducts
b.unique <- list()
b.unique.ab <- list()
#List of resources
c <- list()
c.ab <- list()

#Define eden species
a[1] <- paste("sp.",rstring(1,str.length),sep="")

#Create vector of initial resource requirements for eden species
c0.size <- 20
#Draw random initial resources
c[[1]] <- paste("r.",rstring(c0.size,str.length),sep="")

#Initiate Global Resources + abundances
#The identity of the resource/coproduct/species needs to be paired with numerical abundance
R.id <- c(c[[1]],a[1])
#Draw the abundances of the current resources
R.ab <- sample(seq(1,max.ab),length(R.id)-1)
a1.ab <- 0
R <- data.frame(R.id,c(R.ab,a1.ab),row.names=NULL)
colnames(R) <- c("ID","Abund")


#Establish abundance of Resource use for the eden organism
#i.e. how much of the global resources is the eden organism using?
#This could be a function of an exponential distribution... 
#so that generally resource use is small rather than large
c.ab[[1]] <- numeric(length(c[[1]]))
for (i in 1:length(c[[1]])) {
  res <- which(R$ID == c[[1]][i])
  #Choose whatever is smaller - a random draw or the global amount of each resource
  c.ab[[1]][i] <- min(rexp(1,rate=0.25),R$Abund[res])
}
#Set species abundance
a1.ab <- runif(1)*sum(c.ab[[1]])
a.ab[1] <- a1.ab
#Record species abundance in R
R$Abund[length(c[[1]])+1] <- a1.ab

#Build the coproducts
b[[1]] <- sample(c[[1]],round(runif(1,1,length(c[[1]])-1),0))
#What is the probability that a unique coproduct is formed?
pr.newco <- min(innov.rate * (1/c0.size),1)

#For each coproduct draw a probability of creating a new coproduct
#Create new coproducts in accordance to this probability
draw.newco <- runif(length(b[[1]])) < pr.newco
num.newco <- length(which(draw.newco))
if (num.newco > 0) {
  
  newco.id <- paste("co.",rstring(num.newco,str.length),sep="")
  
  #Update the coproduct list for the eden organism
  b[[1]] <- c(b[[1]],newco.id)
  b.unique[[1]] <- newco.id
}

#Amount of coproducts PRODUCED must equal the sum(resources) - species abundance
num.co <- length(b[[1]])
co.prop <- runif(length(b[[1]]))
co.prop <- co.prop/sum(co.prop)
b.ab[[1]] <- co.prop*(sum(c.ab[[1]]) - a1.ab)
b.unique.ab[[1]] <- b.ab[[1]][seq(num.co-num.newco+1,num.co)]

#Add 0 amt of new coproducts to the Resource List 
#(just the ID, essentially - ab will be added during next step)
R.id <- c(as.character(R$ID),newco.id)
R.ab <- c(R$Abund,rep(0,length(newco.id)))
R <- data.frame(R.id,R.ab,row.names=NULL)
colnames(R) <- c("ID","Abund")

#Add coproduct abundances to the global resource matrix
#Rebuild Global resource matrix
b.id <- as.numeric(unlist(sapply(b[[1]],function(x){which(x == as.character(R$ID))})))
R$Abund[b.id] <- R$Abund[b.id] + b.ab[[1]]


#Create a Resource-In-Use dataframe
R.inuse <- R
tot.res.use <- numeric(length(R$ID))
for (k in 1:length(R$ID)) {
  res <- as.character(R$ID[k])
  #Find which species is using resource i
  sp.res.use <- which(unlist(lapply(c,function(x){res %in% x})))
  if (length(sp.res.use) > 0) {
    #Obtain the abundances of resource i in use
    sp.res.use.ab <- numeric(length(sp.res.use))
    for (j in 1:length(sp.res.use)) {
      sp.res.use.ab[j] <- c.ab[[sp.res.use[j]]][which(c[[sp.res.use[j]]] == res)]
    }
    tot.res.use[k] <- sum(sp.res.use.ab)
  } else {tot.res.use[k] <- 0}
}
R.inuse$Abund <- tot.res.use

#Note that the coproducts are being PRODUCED. 
#So the number of coproducts in R is the number being produced by the presence of an organism.
#If an organism that produces a coproduct dies - if that coproduct is being used by another organism, 
#it might have to die too



#Calculate Global Properties of the System
niche.space[1] <- length(R$ID)
sp.richness[1] <- length(a)
avg.complexity[1] <- mean(unlist(lapply(c,length)))

trophic.edgelist <- list(t.term)
trophic.edgelist[[1]] <- matrix(0,0,2)
trophic.edgelist.w <- list(t.term)
trophic.edgelist.w[[1]] <- numeric()

####################################
#Forward Iterations
####################################


#Dynamic properties of the system




#Begin time iterations
secondary.extinct <- integer()
for (t in 2:t.term) {
  
  print(paste("t=",t,sep=""))
  
  #First, allow mutations for each species
  #Mutation rate
  m.rate <- 0.5
  m.draw <- runif(length(a),0,1) < m.rate
  mut.event <- which(m.draw)
  new.trophic <- matrix(0,0,2)
  new.trophic.w <- numeric()
  #Initiate mutations ~ new species with small differences in respective b (coproduct) and c (resource) vectors
  if (length(mut.event)>0) {
    
    #The IDs of mut.event determine which species are mutating
    new.sp <- numeric(length(mut.event))
    sp.ab <- numeric(length(mut.event))
    #new.sp.ab <- sample(seq(1,max.ab),length(mut.event))
    mut.res <- list()
    mut.res.ab <- list()
    mut.co <- list()
    mut.co.ab <- list()
    mut.co.unique <- list()
    mut.co.unique.ab <- list()
    newco.id <- list()
    newco.ab <- list()
    
    for (i in 1:length(mut.event)) {
      #Which species is speciating?
      mutated <- mut.event[i]
      new.sp[i] <- paste("sp.",rstring(1,str.length),sep="")
      #Resources should be similar to resources of mutated species
      mut.res[[i]] <- c[[mutated]]
      mut.res.ab[[i]] <- c.ab[[mutated]]
      
      #Draw changes in the abundances of resource use.
      #The While Loop ensures that there is SOME abundance of SOME resource
      res.check <- TRUE
      while (res.check) {
        #Randomly select some deviation ~ we may want to skew these values toward zero (combined -ExpDist, ExpDist)
        mut.res.dev <- runif(length(mut.res[[i]]),-1,1)*sd(mut.res.ab[[i]])
        #Apply the deviation
        mut.res.ab[[i]] <- mut.res.ab[[i]] + mut.res.dev
        res.check <- length(which(mut.res.ab[[i]] < 0)) <= 2
      }
      
      #Eliminate resources with abundances <= 0
      elim <- which(mut.res.ab[[i]] <= 0)
      if (length(elim) > 0) {
        mut.res[[i]] <- mut.res[[i]][-elim]
        mut.res.ab[[i]] <- mut.res.ab[[i]][-elim]
      }
      
      #Add a single new resource? Inventiveness measure
      pr.newres <- min(innov.rate * (1/niche.space[t-1]),1)
      draw.newres <- runif(1) < pr.newco
      
      #If there is a new resource drawn to differentiate the new species,
      #draw the resource and draw and abundance from the AVAILABLE global distribution of that abundance 
      #based on the exponetial distribution
      if (draw.newres) {
        #Ensure that the new resource is not already in it's list
        new.res <- mut.res[[i]][1]
        while (new.res %in% mut.res[[i]] == TRUE) {
          new.res <- as.character(sample(R$ID,1))
        }
        #Define the new resource list for the mutated species
        mut.res[[i]] <- c(mut.res[[i]],new.res)
        
        #Determine the abundance of the new resource
        mut.res.ab[[i]] <- c(mut.res.ab[[i]],min(rexp(1,rate=0.25),
                                                 R$Abund[which(as.character(R$ID) == new.res)] -
                                                   R.inuse$Abund[which(as.character(R$ID) == new.res)]))
      }
      
      #Draw the species abundance
      sp.ab[i] <- runif(1)*sum(mut.res.ab[[i]])
      
      #Record any trophic interactions
      #Identify the prey
      prey <- mut.res[[i]][which(grepl("sp.",mut.res[[i]]))]
      if (length(prey > 0)) {
        trophic <- matrix(0,length(prey),2)
        trophic.w <- numeric()
        for (j in 1:length(prey)) {
          
          #Record the identities of the trophic interaction
          trophic[j,] <- c(new.sp[i],prey[j])
          
          #Record the amount consumed ~ was already determined from mut.res.ab
          #Random draw btw 0 and abundance of the resource
          #trophic.w[j] <- runif(1)*mut.res.ab[[i]][which(grepl("sp.",mut.res[[i]]))]
          trophic.w[j] <- mut.res.ab[[i]][which(mut.res[[i]] == prey)]
        }
      }
      
      #Determine co-products of new species (a species cannot be a coproduct!)
      #The number of co-products is constrained to be numb. of resources - 1
      co.full <- mut.res[[i]][which(grepl("sp.",mut.res[[i]])==FALSE)]
      mut.co[[i]] <- sample(co.full,round(runif(1,1,length(co.full)-1),0))
      
      #What is the probability that a unique coproduct is formed?
      pr.newco <- min(innov.rate * (1/niche.space[t-1]),1)
      
      #For each coproduct draw a probability of creating a new coproduct
      #Create new coproducts in accordance to this probability
      draw.newco <- runif(length(mut.co[[i]])) < pr.newco
      num.newco <- length(which(draw.newco))
      if (num.newco > 0) {
        
        newco.id[[i]] <- paste("co.",rstring(num.newco,str.length),sep="")
        #Determine the global abundance of the new coproduct
        #newco.ab[[i]] <- sample(seq(1,new.sp.ab[i]/num.newco),length(newco.id[[i]]))
        #newco <- data.frame(newco.id,newco.ab,row.names=NULL)
        
        #Update the coproduct list for the eden organism
        mut.co[[i]] <- c(mut.co[[i]],newco.id[[i]])
        
      }
      
      #Amount of coproducts PRODUCED must equal the sum(resources) - species abundance
      num.co <- length(mut.co[[i]])
      co.prop <- runif(num.co)
      co.prop <- co.prop/sum(co.prop)
      mut.co.ab[[i]] <- co.prop*(sum(mut.res.ab[[i]]) - sp.ab[i])
      
      #Record the ids abundances of unique coproducts
      if (num.newco > 0) {
        mut.co.unique[[i]] <- newco.id[[i]]
        mut.co.unique.ab[[i]] <- mut.co.ab[[i]][seq(num.co-num.newco+1,num.co)]
      } else {
        mut.co.unique[[i]] <- NA
        mut.co.unique.ab[[i]] <- NA
      }
      
      #Update trophic interactions IF there is a trophic interaction formed such that length(prey) > 0
      if (length(prey) > 0) {
        if (length(new.trophic[,1]) == 0) {
          new.trophic <- trophic
          new.trophic.w <- trophic.w
        } else {
          new.trophic <- rbind(new.trophic,trophic)
          new.trophic.w <- c(new.trophic.w,trophic.w)
        }
      }
    
    } #End loop over mut.events (i)
    
    #Updating
    
    #Update Species list
    a <- c(a,new.sp)
    a.ab <- c(a.ab,sp.ab)
    c <- c(c,mut.res)
    c.ab <- c(c.ab,mut.res.ab)
    b <- c(b,mut.co)
    b.ab <- c(b.ab,mut.co.ab)
    b.unique <- c(b.unique,mut.co.unique)
    b.unique.ab <- c(b.unique.ab,mut.co.unique.ab)
    
    #Add 0 amt of NEW coproducts to the Resource List 
    #(just the ID, essentially - ab will be added during next step)
    R.id <- c(as.character(R$ID),new.sp,unlist(newco.id))
    R.ab <- c(R$Abund,sp.ab,rep(0,length(unlist(newco.id))))
    R <- data.frame(R.id,R.ab,row.names=NULL)
    colnames(R) <- c("ID","Abund")
    
    #Add ALL coproduct abundances to the global resource matrix for each new species i
    #Rebuild Global resource matrix
    for (j in 1:length(mut.event)) {
      b.id <- as.numeric(unlist(sapply(mut.co[[j]],function(x){which(x == as.character(R$ID))})))
      R$Abund[b.id] <- R$Abund[b.id] + mut.co.ab[[j]]
    }    

    #Update Resources-In-Use dataframe
    R.inuse.new <- R
    tot.res.use <- numeric(length(R$ID))
    for (k in 1:length(R$ID)) {
      res <- as.character(R$ID[k])
      #Find which species is using resource k
      sp.res.use <- which(unlist(lapply(c,function(x){res %in% x})))
      if (length(sp.res.use) > 0) {
        #Obtain the abundances of resource i in use
        sp.res.use.ab <- numeric(length(sp.res.use))
        for (j in 1:length(sp.res.use)) {
          sp.res.use.ab[j] <- c.ab[[sp.res.use[j]]][which(c[[sp.res.use[j]]] == res)]
        }
        tot.res.use[k] <- sum(sp.res.use.ab)
      } else {tot.res.use[k] <- 0}
    }
    R.inuse.new$Abund <- tot.res.use
    R.inuse <- R.inuse.new
    
  } #End speciation Loop
  
  
  
  
  

  #Determine similarities in resource use among species
  #CURRENTLY DOES NOT TAKE ABUNDANCES INTO ACCOUNT
  if (length(a) > 1) {
  sim.m <- matrix(0,length(a),length(a))
  for (k in 1:length(a)) {
    for (j in 1:length(a)) {
      sim.m[k,j] <- string.similarity(c[[k]],c.ab[[k]],c[[j]],c.ab[[j]])[2] #[1] = Jaccard; [2] = Cosine Sim Index
    }
  }
  #Eliminate the effect of competition with yourself
  diag(sim.m) <- 0
  #Competitive pressure is proportional to the number of potential competitions (Num. species - 1)
  comp.pres <- apply(sim.m,2,sum) / (length(sim.m[,1]) - 1)
  } else {
    comp.pres <- 0
  }
  
  
  
  #Update system trophic edgelist
  #The consumers are in the left column and the prey are in the right column
  #If there has NOT been an additional trophic interaction formed
  if (length(new.trophic) == 0) {
    trophic.edgelist[[t]] <- trophic.edgelist[[t-1]]
    trophic.edgelist.w[[t]] <- trophic.edgelist.w[[t-1]]
  } else {
    #If this is the first trophic interaction, AND there has been an additional trophic interaction formed
    if ((length(trophic.edgelist[[t-1]][,1]) == 0) && (length(new.trophic) > 0)) {
      trophic.edgelist[[t]] <- new.trophic
      trophic.edgelist.w[[t]] <- new.trophic.w
    } 
    #If this is not the first trophic interaction, and there has been an additional trophic interaction formed
    if ((length(trophic.edgelist[[t-1]][,1]) > 0) && (length(new.trophic) > 0)) {
      trophic.edgelist[[t]] <- rbind(trophic.edgelist[[t-1]],new.trophic)
      trophic.edgelist.w[[t]] <- c(trophic.edgelist.w[[t-1]],new.trophic.w)
    }
  }
  
  #What are the predation pressures for each species?
  #Trophic weight if species is prey / Total abundance of the species
  pred.pres <- numeric(length(a))
  for (j in 1:length(a)) {
    pred.pres[j] <- max(0,trophic.edgelist.w[[t]][which(trophic.edgelist[[t]][,2] == a[j])]) / R$Abund[which(as.character(R$ID) == a[j])]
  }
  
  
  
  
  #Set dynamic rates
  #Extinction rate :: should increase with competition load and predation load... we can play around with the relative weights
  ext.background <- 0.01
  ext.rate <- (ext.background + 0.25*comp.pres + 0.75*pred.pres)
  draw.ext <- runif(length(a),0,1) < ext.rate
  
  if (all(draw.ext)) { stop("You are all alone with your simulation.") }
  
  #Combine newly eliminated species with the secondary-extinct species from the previous timestep
  extinct <- c(which(draw.ext),secondary.extinct)
  
  ######################
  # Induce extinctions #
  ######################
  
  #Modify R.inuse matrix
  #Modify trophic interactions + trophic interaction weights
  #Determine whether coproducts of extinct species are unique
  #If coproducts are unique, eliminate them from the Global Resources
  
  #This corrects for the effects of extinction across all extinct species at once
  
  
  if (length(extinct) > 0) {
    
    #Delete trophic interactions involving the extinct species
    #Nothing happens if there are no preds/prey that go extinct
    #The if statement just gets around the peculiarity of R treating a matrix w/ single row differently
    
    #If the trophic.edgelist matrix got turned into a vector, then turn it back into a matrix
    if (is.vector(trophic.edgelist[[t]]) == TRUE) {
      trophic.edgelist[[t]] <- as.matrix(t(trophic.edgelist[[t]]))
    }
    #     
    #     
    #     #If there is just one trophic interaction... then it is eliminated and the matrix form of trophic.edgelist is retained
    #     if (length(trophic.edgelist[[t]]) == 2) {
    #       
    #       pred.extinct <- which(trophic.edgelist[[t]][1] == a[extinct])
    #       prey.extinct <- which(trophic.edgelist[[t]][2] == a[extinct]) #this also records the ID of the predators that are consuming the extinct prey
    #       
    #       #Eliminate the single trophic interaction
    #       #Ensure that trophic.edgelist[[t]] remains a MATRIX and not a VECTOR
    #       trophic.edgelist[[t]] <- matrix(0,0,2)
    #       trophic.edgelist.w[[t]] <- integer(0)
    #     } else {
    #       

    pred.extinct <- which(trophic.edgelist[[t]][,1] == a[extinct])
    prey.extinct <- which(trophic.edgelist[[t]][,2] == a[extinct]) #this also records the ID of the predators that are consuming the extinct prey
    
    #Combine ids of extinct predator and prey interactions
    elim.ints <- unique(c(pred.extinct,prey.extinct))
    
    #Eliminate all rows that contain either the predator or the prey trophic interaction
    trophic.edgelist[[t]] <- trophic.edgelist[[t]][-elim.ints,]
    #Eliminate all elements that contain
    trophic.edgelist.w[[t]] <- trophic.edgelist.w[[t]][-elim.ints]
      
    #}

    
    #Identify species and their unique coproducts to be eliminated from the Resource Matrix
    extinct.unique <- as.character(na.omit(c(a[extinct],unlist(b.unique[extinct]))))
    
    #Revise R by coproduct abs (this is what the extinct species was providing to R)
    #Revise R.inuse by the res abs (this is what the extinct species was taking away from R)
    
    #Modify Resources-in-use by ALL extinct species - combine abundance amongst like resources
    modify.res.id <- unlist(c[extinct])
    modify.res.ab <- unlist(c.ab[extinct])
    for (j in 1:length(modify.res.id)) {
      R.id <- which(as.character(R.inuse$ID) == modify.res.id[j])
      R.inuse$Abund[R.id] <- R.inuse$Abund[R.id] - modify.res.ab[j]
    }
    
    #Modify coproducts producted by ALL extinct species - combine abundance amongst like resources
    modify.coprod.id <- unlist(b[extinct])
    modify.coprod.ab <- unlist(b.ab[extinct])
    for (j in 1:length(modify.coprod.id)) {
      R.id <- which(as.character(R$ID) == modify.coprod.id[j])
      R$Abund[R.id] <- R$Abund[R.id] - modify.coprod.ab[j]
    }
    
    #Update R and R.use
    #Eliminate SPECIES + UNIQUE COPRODUCTS and their corresponding abundances from the R and R.inuse matrix
    del.R <- as.numeric(sapply(extinct.unique,function(x){which(x == as.character(R$ID))}))
    R <- R[-del.R,]
    R.inuse <- R.inuse[-del.R,]
    
    #Update the lists to exclude any extinctions that have just occurred
    a <- a[-extinct]
    a.ab <- a.ab[-extinct]
    c <- c[-extinct]
    c.ab <- c.ab[-extinct]
    b <- b[-extinct]
    b.ab <- b.ab[-extinct]
    b.unique <- b.unique[-extinct]
    b.unique.ab <- b.unique.ab[-extinct]
    
    #Identify SECONDARY EXTINCTIONS
    #These are species that use resources/coproducts/species that are eliminated during this timestep
    #They will be eliminated in the next timestep along with the species that go extinct due to stochastic effects
    secondary.extinct <- which(unlist(lapply(c,function(x){any(extinct.unique %in% x)})))

        
    #     for (j in 1:length(prey.extinct)) {
    #       pred.id <- prey.extinct[j]
    #       prey.id <- 
    #         c[[pred.id]] <- c[[pred.id]][-which(c[[pred.id]] == )]
    #       c.ab[[j]] 
    #     }
    
  } #End 'induce extinctions'
  
  #Record Stats
  
  #Calculate Global Properties of the System
  niche.space[t] <- length(R$ID)
  sp.richness[t] <- length(a)
  avg.complexity[t] <- mean(unlist(lapply(c,length)))
  
}




plot(niche.space,type="l")

plot(sp.richness,type="l")

plot(avg.complexity,type="l")




















