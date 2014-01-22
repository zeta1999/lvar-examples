{-# LANGUAGE DataKinds #-}

import Control.LVish
import Control.LVish.DeepFrz
import Data.LVar.Generic (addHandler)
import Data.LVar.PureSet
import qualified Data.Graph as G
import qualified Data.Set as S

-- A toy graph for demonstration purposes.
myGraph = first $ G.graphFromEdges [("node0", 0, [1, 6, 7]),
                                    ("node1", 1, [4]),
                                    ("node2", 2, [1]),
                                    ("node3", 3, []),
                                    ("node4", 4, [3, 5]),
                                    ("node5", 5, [3]),
                                    ("node6", 6, [10]),
                                    ("node7", 7, []),
                                    ("node8", 8, []),
                                    ("node9", 9, [4, 11]),
                                    ("node10", 10, [9]),
                                    ("node11", 11, [10])]

-- Argh!  Why isn't this built in?!
first (x, _, _) = x

-- Takes a graph and a vertex and returns a list of the vertex's
-- neighbors.  This seems silly, but it's the first thing that comes
-- to mind given the Data.Graph API.
neighbors :: G.Graph -> G.Vertex -> [G.Vertex]
neighbors g v =
  map snd edgesFromNode where
    edgesFromNode = filter (\(v1, _) -> v1 == v) (G.edges g)

-- so, this occasionally produces the right answer, but more often I
-- get "thread blocked indefinitely in an MVar operation"
p :: G.Graph -> G.Vertex -> Par QuasiDet s (S.Set G.Vertex)
p g startNode = do
  seen <- newEmptySet
  hp <- newPool
  insert startNode seen
  addHandler (Just hp) seen
    (\node -> do
        mapM (\v -> insert v seen) (neighbors g node)
        return ())
  quiesce hp
  freezeSet seen

main = do
  v <- runParIO $ p myGraph (0 :: G.Vertex)
  putStr $ show v
