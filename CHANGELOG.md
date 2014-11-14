## 0.4.3 (November 13, 2014) ##

*   Don't attempt to hide legs which haven't been built yet
    (regression from the 'lazy building' of legs).


## 0.4.2 (July 31, 2014) ##

*   Cleanup leg option handling code.

*   Test additions/updates.

*   Remove tourbus data from original element when destroying tour.

    _Joshua Jabbour_

*   Fix incorrect `target` attribute in docs to be `container`.

    _Joshua Jabbour_


## 0.4.1 (June 30, 2014) ##

*   Update `bower.json` to specify primary endpoints.

    _Bruno Batista_


## 0.4.0 (June 28, 2014) ##

*   Use `browserify` to split up the monolithic `jquery-tourbus.coffee` into
    submodules.

*   Rename Bus `target` option to `container`. This was confusing because
    `target` is used on legs to refer to what the tour leg 'points at' or is
    attached to. Now it's more in line with what the option is: where the
    tour elements will be created.

*   Add `class` option to Bus and Leg options (and also add support for
    the declarative style on both (`data-class='something'`).

    Fixes #9

*   Lazily load Legs instead of all up front on 'departure'. As a result,
    expose Bus `buildLeg` function one can use to force-build a leg if necessary.

    Fixes #5

*   Don't call `stop` internally, trigger the appropriate event.

    Sort of fixes #14

*   Bus now inserts a container element.

*   Bus now has `rawData` like legs do, and you can set all options
    except the callbacks (eg, `autoDepart`, but not `onDepart`).

*   Switch docs examples from using `$(document).ready` to `$(window).load`
    because we need the size of the window to be known in order to
    accurately position things sometimes.

    Fixes #7
