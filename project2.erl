-module(project2).
-import(io, [fwrite/1, fwrite/2, format/2]).
-export([main/3, lineTopology/1, createProcesses/3, rumor/2, pushsum/4, column2DLinks/3]).

selectRandomNeighbour(Pid) ->
    Neighbours = element(2, process_info(Pid, links)),
    SelectdNeighbour = lists:nth(rand:uniform(length(Neighbours)), Neighbours),
    SelectdNeighbour.

lineTopology(NodeList) ->
    NumNodes = length(NodeList),

    if 
        (NumNodes>2) ->
            [N1,N2|_] = NodeList,
            N2 ! {link , N1},
            List1 = lists:delete(N1,NodeList),
            lineTopology(List1);

        true ->
            [N1,N2] = NodeList,
            N2 ! {link , N1}
    end.

fullTopology([]) ->
    ok;
fullTopology(NodeList) ->
    [N1 | Tail] = NodeList,


    lists:foreach(
        fun(Node) ->
            Node ! {link, N1}
        end,
        Tail
    ),
    %format("I ~p, have links to: ~p~n",[N1, process_info(N1, links)]),
    UpdatedList = lists:delete(N1,NodeList),
    fullTopology(UpdatedList).

segmentGridTopology(NodeList, SegmentedList, TempList, Index, Side) ->
    if 
        (Index rem Side) =:= 0 ->
            if 
                (Index =:= length(NodeList)) ->
                    lists:append(SegmentedList, [TempList ++ [lists:nth(Index, NodeList)]]);
                true ->
                    segmentGridTopology(NodeList, lists:append(SegmentedList, [TempList ++ [lists:nth(Index, NodeList)]]), [], Index+1, Side)
            end;
        true ->
            segmentGridTopology(NodeList, SegmentedList, lists:append(TempList, [lists:nth(Index, NodeList)]), Index+1, Side)
    end.

column2DLinks(SegmentedList, Index, Rows) ->
    if 
        (Index /= Rows) ->
            Row1 = lists:nth(Index, SegmentedList),
            Row2 = lists:nth(Index+1, SegmentedList),

            lists:foreach(
                fun(Node) ->
                    N1 = element(1, Node),                  
                    N2 = element(2, Node),
                    N1 ! {link, N2}
                end,
                lists:zip(Row1, Row2)
            ),
            column2DLinks(SegmentedList, Index+1, Rows);
        true -> ok
    end.

gridimp3DTopology(NodeList) ->
    NumNodes = length(NodeList),
    Side = round(math:sqrt(NumNodes)),
    SegmentedList = segmentGridTopology(NodeList, [], [], 1, Side),
    lists:foreach(
        fun(SideList) ->
            lineTopology(SideList)
        end,
        SegmentedList
    ),
    column2DLinks(SegmentedList, 1, Side).

grid2DTopology(NodeList) ->
    NumNodes = length(NodeList),
    Side = round(math:sqrt(NumNodes)),
    SegmentedList = segmentGridTopology(NodeList, [], [], 1, Side),
    lists:foreach(
        fun(SideList) ->
            lineTopology(SideList)
        end,
        SegmentedList
    ),
    column2DLinks(SegmentedList, 1, Side).

rumor(Master, Counter) ->
    receive
        {link, Pid} ->
            link(Pid),
            % format("I ~p, have a linked process: ~p. My Links: ~p~n", [self(), Pid, process_info(self(), links)]),
            rumor(Master, Counter);
        {gossip} ->
            if
                Counter =:= 10 ->
                    format("I ~p got gossip 10 times~n", [self()]),
                    Master ! {gossipSent},
                    rumor(Master, Counter+1);
                Counter > 10 ->
                    SelectdNeighbour = selectRandomNeighbour(self()),
                    SelectdNeighbour ! {gossip},
                    rumor(Master, Counter);
                true ->                    
                    SelectdNeighbour = selectRandomNeighbour(self()),
                    SelectdNeighbour ! {gossip},
                    rumor(Master, Counter+1)
            end
    after 1000 ->
        if 
            Counter < 10 ->
                % format("I ~p am retrying N~n", [self()]),
                SelectdNeighbour = selectRandomNeighbour(self()),
                SelectdNeighbour ! {gossip},
                rumor(Master, Counter);
        true ->
            % format("I ~p am retrying WN~n", [self()]),
            rumor(Master, Counter)
        end
    end.

pushsum(Master, S, W, Previous) ->
    receive
        {link, Pid} ->
            link(Pid),
            % format("I ~p, have a linked process: ~p. My Links: ~p~n", [self(), Pid, process_info(self(), links)]),
            pushsum(Master, S, W, Previous);

        {pushsum, RecS, RecW} ->
            FinalS = (S+RecS) / 2,
            FinalW = (W+RecW) / 2,
            SelectdNeighbour = selectRandomNeighbour(self()),
            SelectdNeighbour ! {pushsum, FinalS, FinalW},
            FinalSW = FinalS/FinalW,
            if 
                length(Previous) < 3 -> 
                    pushsum(Master, FinalS, FinalW, lists:append(Previous, [FinalSW]));
                true ->
                    % format("Previous 1 ~p~n", [Previous]),
                    [N1, N2, N3 | _] = lists:reverse(Previous),
                    A = abs(FinalSW - S/W),
                    B = abs(N1 - N2),
                    C = abs(N2 - N3),
                    D = math:pow(10, -10),
                    if 
                        (A < D) and (B < D) and (C < D) -> 
                            Master ! {pushsum},
                            exit("Done");
                        true -> pushsum(Master, FinalS, FinalW, lists:append([lists:last(Previous)], [FinalSW]))
                    end                    
            end
        after 10000 ->
            if 
                length(Previous) > 0 ->
                    FinalS = S/2,
                    FinalW = W/2,
                    SelectdNeighbour = selectRandomNeighbour(self()),
                    SelectdNeighbour ! {pushsum, FinalS, FinalW},
                    FinalSW = FinalS/FinalW,
                    if 
                        length(Previous) < 3 -> 
                            pushsum(Master, FinalS, FinalW, lists:append(Previous, [FinalSW]));
                        true ->
                            % format("Previous 2 ~p~n", [Previous]),
                            [N1, N2, N3 | _] = lists:reverse(Previous),
                            A = abs(FinalSW - S/W),
                            B = abs(N1 - N2),
                            C = abs(N2 - N3),
                            D = math:pow(10, -10),
                            if 
                                (A < D) and (B < D) and (C < D) -> Master ! {pushsum};
                                true -> pushsum(Master, FinalS, FinalW, lists:append([lists:last(Previous)], [FinalSW]))
                            end                  
                    end;
                true -> pushsum(Master, S, W, Previous)
            end
        end.

createProcesses(0, _, NodeList) ->
    NodeList;
createProcesses(NumNodes, "pushsum", NodeList) ->
    Worker = spawn(project2, pushsum, [self(), NumNodes, 1, []]),
    Temp = [Worker | NodeList],
    createProcesses(NumNodes - 1, "pushsum", Temp);
createProcesses(NumNodes, "gossip", NodeList) ->
    Worker = spawn(project2, rumor, [self(), 0]),
    Temp = [Worker | NodeList],
    createProcesses(NumNodes - 1, "gossip", Temp).

checkConvergence(0) ->
    fwrite("All nodes received gossip~n");
checkConvergence(NodesToInform) ->
    receive
        {gossipSent} ->
            format("Completed a node, number of nodes remaing: ~p~n", [NodesToInform-1]),
            checkConvergence(NodesToInform-1);
        {pushsum} ->
            fwrite("No significant change in last 3 rounds~n")
    end.

main(NumNodes, Algorithm, Topology) ->
    register(project2, self()),

    case Topology of
        "line" -> 
            NodeList = createProcesses(NumNodes, Algorithm, []),
            fwrite("Initial NodeList ~p~n",[NodeList]),
            lineTopology(NodeList);
        "full" ->
            NodeList = createProcesses(NumNodes, Algorithm, []),
            fwrite("Initial NodeList ~p~n",[NodeList]),
            fullTopology(NodeList);
        "2d" ->
            AdjustedNumNodes = round(math:pow(round(math:sqrt(NumNodes)), 2)),
            NodeList = createProcesses(AdjustedNumNodes, Algorithm, []),
            fwrite("Initial NodeList ~p~n",[NodeList]),
            grid2DTopology(NodeList);
        "imp3d" ->
            AdjustedNumNodes = round(math:pow(round(math:sqrt(NumNodes)), 2)),
            NodeList = createProcesses(AdjustedNumNodes, Algorithm, []),
            fwrite("Initial NodeList ~p~n",[NodeList]),
            gridimp3DTopology(NodeList)
    end,

    case Algorithm of
        "gossip" ->
            [N1 | _] = NodeList,
            format("Sending the First Node ~p a gossip~n", [N1]),
            statistics(wall_clock),
            N1 ! {gossip};
        "pushsum" ->
            [N1 | _] = NodeList,
            format("Sending the First Node ~p a gossip~n", [N1]),
            statistics(wall_clock),
            N1 ! {pushsum, 0, 0}

    end,

    checkConvergence(length(NodeList)),
    {_, T2} = statistics(wall_clock),
    format("Convergence Time: ~p~n",[T2]),
    lists:foreach(
        fun(Pid) ->
            exit(Pid, "done")
        end,
        NodeList
    ),
    unregister(project2).