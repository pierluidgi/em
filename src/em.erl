%%%----------------------------------------------------------------------
%%% File    : em.erl
%%% Author  : Aleksey S. Kluchnikov <alexs@ximad.com>
%%% Purpose : Event Meter
%%% Created : 21 Oct 2014
%%%----------------------------------------------------------------------

%% func_name_ - internal call gen_server func
%% func_name__ - internal cast gen_server func

-module(em).
-behaviour(gen_server).
-include("em.hrl").

-export([start_link/0, handle_info/2, code_change/3, terminate/2]).
-export([init/1, handle_call/3, handle_cast/2, code_reload/0]).


-export([
  set_all/1,
  get_all/0,
  event/1, event__/2,
  get/1, get_/2,
  list/0, list_/1
]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Gen Server api
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
init([]) -> {ok, []}.
handle_info(_Message, State) -> {noreply, State}.
code_reload() -> State = get_all(), code_change([], State, []).
code_change(_OldVersion, State, _Extra) -> {ok, State}.
terminate(_Reason, _State) -> ok.

%%casts
handle_cast({run, Func, Args}, State) -> apply(?MODULE, Func, [State|Args]);
handle_cast(_Req, State) -> {noreply, State}.
%%calls
handle_call(get_all, _From, State) -> {reply, State, State};
handle_call({set_all, NewState}, _From, _State) -> {reply, ok, NewState};
handle_call({run, Func, Args}, _From, State) -> apply(?MODULE, Func, [State|Args]);
handle_call(_Req, _From, State) -> {reply, unknown_command, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%
set_all(State) -> gen_server:call(?MODULE, {set_all, State}).
get_all() -> gen_server:call(?MODULE, get_all).



%% Hit event
event(EventName) -> gen_server:cast(?MODULE, {run, event__, [EventName]}).
event__(State, EventName) ->
  Mavg = case ?GV(EventName, State, u) of u -> jn_mavg:new_mavg(300); V -> V end,
  {noreply, ?KS(EventName, jn_mavg:bump_mavg(Mavg, 1), State)}.

%% Get stat
get(EventName) -> gen_server:call(?MODULE, {run, get_, [EventName]}).
get_(State, EventName) ->
  Answer = 
    case ?GV(EventName, State, u) of 
      u -> noext; 
      Mavg -> {ok, jn_mavg:getEventsPer(Mavg, 60)}
    end,
  {reply, Answer, State}.


%% List stat
list() -> gen_server:call(?MODULE, {run, list_, []}).
list_(State) -> {reply, [{EventName, jn_mavg:getEventsPer(Mavg, 60)}||{EventName, Mavg} <- State], State}.
 
