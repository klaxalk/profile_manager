# Dotprofiler
 
creating profiles in linux dotfiles

## Description 

## Premise

This piece of software allows to create profiles in linux _dotfiles_.
The profiles can be maintained within a single branch on git, which streamlines the proces of sharing configuration between various devices and even users, both of which might need minor customizations in othewise mostly universal set of files.
The authors personal experience suggests that maintaining minor customizations in git branches often leads to difficult rebasing, which generally slows down the process of pushing new changes from any devices to any other device, resulting in fractured setup.
Thus appeared the idea to contain each version of the configuration within the file.
The section will be activated by uncommenting it only on the device (or by a user) which it is meant for.
Dotprofiler takes care of automatic commenting/uncommenting of sections of dotfiles via an updated _git_ command with custom hooks.

## Dependencies

Dotprofiler depends (through [Epigen](https://github.com/klaxalk/epigen) on
1. **bash**,
2. **vim** (7.0 or higher).
No special configuration is needed for either of those.

Epigen utilizes Tim Pope's [vim-commentary](https://github.com/tpope/vim-commentary) vim plugin, which has been integrated in the Epigen's .vimrc.
