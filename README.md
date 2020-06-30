# ScenePortal2D
A Godot Asset to emulate RPG-Maker portal-events and scene changes.

## Purpose

Changing scenes seems one of the most hairy problems Godot newbie are facing with.
While other games have a clear concept of "level" and simple ways you can transfer 
between them, Godot has a much more powerful concept of "scene", but moving between 
them requires ad-hoc scripting.

This module is an attempt at standardization of the scene changing, and offers a 
powerful set of objects to help you design both level transfers and programmatic
scene transition.

* The SceneChanger obect can be directly used to change scene, optionally using 
  transitions objects to perform visual transition between scenes.
* The SceneChangerCtrl object provided can program the scene changer, so that you
  need writing less code, and rely on GUI to configure your scene changes.
* ScenePortal2D objects can be placed in your levels, and given a target scene and
  exit portal directly from the UI, without any script.
* Transition controls can be added to the SceneChangerCtrl and to the portals to
  configure scene transitions without having to script them.

## Minimal Set Up

1. Set the SceneChanger object as AutoLoad in the project.
1. You may want to add a transition control (*\_ctrl.tscn) under SceneChanger and
   rename it as `DefaultTransition` to take advantage of this feature application-wide.
1. Your player object can implement a `set_portal_facing(direction)` method, to automate
   its facing on exit from a portal.
1. By default, portal objects (ScenePortal2D) listen to collision levels 1 and 2. You may
   want to configure this.
1. Your transferable entity (usually the Player) __must__ be assigned the `Player` group.
