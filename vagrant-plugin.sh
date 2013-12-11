#!/usr/bin/env bash


plugins=(vagrant-omnibus vagrant-list vagrant-hosts vagrant-berkshelf vagrant-cachier)

plugin_install() {
   
    for i in ${plugins[@]}; do
        vagrant plugin install ${i}
    done
    exit 0
}

plugin_uninstall() {
    for i in ${plugins[@]}; do
        vagrant plugin uninstall ${i}
    done
    exit 0
}


case "$1" in
        install)
            plugin_install
            ;;
         
        uninstall)
            plugin_uninstall
            ;;
         
        *)
            echo $"Usage: $0 {install|uninstall}"
            exit 1
 
esac
