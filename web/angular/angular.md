## Architecture Overview

* NgModule
  * compilation context
  * root module (AppModule)
    * bootstrap
    * root component

* Component
  * view
    * template
      * html + css
      * angular directive
      * binding markup
        * event binding
        * property binding
        * two-way data binding
      * pipe
  * service
    * dependency injection
    * router
      * lazy-loading
      * navigation paths

* decorator

## Introduction to Modules

`@NgModule()` decorator

properties:
* declarations
* exports
* imports
* providers
* bootstrap

exports/imports是对于component template来说的，`.ts`文件遵守ts的模块规则.

compilation context

view
* host view
* view hierarchy
* embedded view
* nesting

## Introduction to Components

lifecycle hook

`@Component()`
* selector
* templateUrl
  * view
* providers
  * service dependency-injection

  ### template syntax

  * data-binding

    * one-way
      * dom-to-component
      * component-to-dom
    * two-way

    * interpolation
    * property-binding
    * event-binding

    * javaScript event cycle
  * pipe

`@Pipe` decorator
pipe operator `|`
pipe can take parameter

`@Directive()` decorator.
* `@Component()`
  * `@Component()` decorator extends `@Directive()` decorator.
* structural directive
  * adding, removing, and replacing elements in the DOM
* attribute directive
  * alter the appearance or behavior of an existing element

## Introduction to Servie and Dependency Injection

`@Injectable` decorator

injector
provider
  * root injector level
  * NgModule level
  * component level
service