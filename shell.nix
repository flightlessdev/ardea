with (import <nixpkgs> {

});
mkShell {
    buildInputs = [
        erlangR26
        elixir_1_15
        rebar3


    ];
    HISTFILE = "${toString ./.}/.bash_history";

    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
    shellHook = ''
        mkdir -p .mix
        mkdir -p .hex
        export MIX_HOME=$PWD/.mix
        export MIX_ARCHIVES=$MIX_HOME/archives
        export HEX_HOME=$PWD/.hex
        export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
        export BUILD_WITHOUT_QUIC=1 # For exmqtt dep
        export ERL_AFLAGS="-kernel shell_history enabled"
        mix archive.install --force github hexpm/hex tag v2.0.5
        mix local.rebar rebar3 --force ${pkgs.rebar3}/bin/rebar3
        source .env
'';
}
