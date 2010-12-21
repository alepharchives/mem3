% Copyright 2010 Cloudant
%
% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(mem3_sync_event).
-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2,
    code_change/3]).

init(_) ->
    {ok, nil}.

handle_event({add_node, Node}, State) ->
    %% this guy has odd behavior if a node had been deleted from nodes,
    %% the node brought down and then brought back up
    %% io:format("a node was just added ~p ~n",[Node]),
    Db1 = list_to_binary(couch_config:get("mem3", "node_db", "nodes")),
    Db2 = list_to_binary(couch_config:get("mem3", "shard_db", "dbs")),
    [mem3_sync:push(Db, Node) || Db <- [Db1, Db2]],
    {ok, State};

handle_event({nodeup, Node}, State) ->
    io:format("a node just came up ~p ~n",[Node]),
    case lists:member(Node, mem3:nodes()) of
    true ->
        Db1 = list_to_binary(couch_config:get("mem3", "node_db", "nodes")),
        Db2 = list_to_binary(couch_config:get("mem3", "shard_db", "dbs")),
        [mem3_sync:push(Db, Node) || Db <- [Db1, Db2]];
    false ->
        ok
    end,
    {ok, State};

handle_event({Down, Node}, State) when Down == nodedown; Down == remove_node ->
    %%io:format("a node was : ~p ~p ~n",[Down,Node]),
    mem3_sync:remove_node(Node),
    {ok, State};

handle_event(_Event, State) ->
    {ok, State}.

handle_call(_Request, State) ->
    {ok, ok, State}.


handle_info(_Info, State) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
