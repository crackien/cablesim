-module(cablesim_app).
%-compile([debug_info, export_all]).
-behaviour(application).
-include("device.hrl").

%% Application callbacks
-export([start/2, stop/1, start_cablemodem/2, do_startcm/0]).

-export([mk_cms/4]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    error_logger:logfile({open, "/tmp/cablesim.log"}),
    X = cablesim_sup:start_link(),
    simulate(5000),
    X.

stop(_State) ->
    ok.

%%
%% Utitlity function to start a cable modem emulation
%%
start_cablemodem(Device, BehindDevs) ->
    % first start the cable modem process
    supervisor:start_child(
      cablesim_sup, {Device#device.server_id,
                     {cm, start_link, [Device, BehindDevs]}, 
                     transient, 5000, worker, dynamic}),
    % then create cable modem's dhcp module
    DeviceTempl = Device#device.template,
    supervisor:start_child(
      cablesim_sup, {Device#device.dhcp_client,
                     {DeviceTempl#device_template.dhcp_module, start_link,
                      [Device#device.dhcp_client, Device]},
                     transient, 5000, worker, dynamic}),
    % Create dhcp server component on all behind-devices
    lists:foreach(fun (F_D) ->
                          F_DT = F_D#device.template,
                          supervisor:start_child(
                            cablesim_sup, {F_D#device.dhcp_client,
                                           {F_DT#device_template.dhcp_module, 
                                            start_link, [F_D#device.dhcp_client, F_D]},
                                           transient, 5000, worker, dynamic})
                  end,
                  BehindDevs).
%%
%% Utility function to start a cable modem emulation of 1 Netgear CG3000.
%% 
do_startcm() ->
    [CMTempl, MTATempl, CPETempl] = device:cpedb(),
    CM_Dev = #device{server_id = cm1, upstream_id = cmts, mac = {0,0,0,0,0,1}, 
                     dhcp_client = cm1_dhcp,
                     template = CMTempl},
    MTA_Dev = #device{server_id = cm1_mta, upstream_id = cm1, mac = {0,0,0,0,0,2},
                      dhcp_client = cm1_mtadhcp,
                      template = MTATempl},
    CPE_Dev = #device{server_id = cm1_cpe, upstream_id = cm1, mac = {0,0,0,0,0,3},
                      dhcp_client = cm1_cpedhcp,
                      template = CPETempl},
    start_cablemodem(CM_Dev, [CPE_Dev,MTA_Dev]).

simulate(N) ->
    [CMTempl, MTATempl, CPETempl] = device:cpedb(),
    mk_cms(N, CMTempl, MTATempl, CPETempl).

mk_cms(0, _, _, _) -> ok;
mk_cms(N, CMTempl, MTATempl, CPETempl) ->
    CM_id = mk_atom(cm, N),
    MTA_id = mk_atom(cm, N, mta),
    CPE_id = mk_atom(cm, N, cpe),
    CM_dhcp_id = mk_atom(cm, N, dhcp),
    MTA_dhcp_id = mk_atom(cm, N, mtadhcp),
    CPE_dhcp_id = mk_atom(cm, N, cpedhcp),
    A = 3 * N div 200,
    B = 3 * N rem 200,
    io:format("Mac-part: ~p ~p ~p~n", [N, A, B]),
    CM_Dev = #device{server_id = CM_id, upstream_id = cmts, mac = {0,0,0,0,A,B}, 
                     dhcp_client = CM_dhcp_id,
                     template = CMTempl},
    MTA_Dev = #device{server_id = MTA_id, upstream_id = CM_id, mac = {0,0,0,0,A,B+1},
                      dhcp_client = MTA_dhcp_id,
                      template = MTATempl},
    CPE_Dev = #device{server_id = CPE_id, upstream_id = CM_id, mac = {0,0,0,0,A,B+2},
                      dhcp_client = CPE_dhcp_id,
                      template = CPETempl},
    start_cablemodem(CM_Dev, [CPE_Dev,MTA_Dev]),
    cm:poweron(CM_id),
    mk_cms(N-1, CMTempl, MTATempl, CPETempl).
    
    
mk_atom(Prefix, N) ->
   list_to_atom(atom_to_list(Prefix) ++ "_" ++ integer_to_list(N)).
mk_atom(Prefix, N, Postfix) ->
   list_to_atom(atom_to_list(Prefix) ++ "_" ++ integer_to_list(N)  ++ "_" ++ atom_to_list(Postfix)).
