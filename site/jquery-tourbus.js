(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
//@ sourceMappingURL=jquery-tourbus.map
(function() {
  var $, Bus, Leg, methods, tourbus,
    __slice = [].slice;

  $ = jQuery;

  Bus = require('./modules/bus');

  Leg = require('./modules/leg');

  tourbus = $.tourbus = function() {
    var args, method;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    method = args[0];
    if (methods.hasOwnProperty(method)) {
      args = args.slice(1);
    } else if (method instanceof $) {
      method = 'build';
    } else if (typeof method === 'string') {
      method = 'build';
      args[0] = $(args[0]);
    } else {
      $.error("Unknown method of $.tourbus --", args);
    }
    return methods[method].apply(this, args);
  };

  $.fn.tourbus = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return this.each(function() {
      args.unshift($(this));
      tourbus.apply(null, ['build'].concat(__slice.call(args)));
      return this;
    });
  };

  methods = {
    build: function(el, options) {
      var built;
      if (options == null) {
        options = {};
      }
      options = $.extend(true, {}, tourbus.defaults, options);
      built = [];
      if (!(el instanceof $)) {
        el = $(el);
      }
      el.each(function() {
        return built.push(new Bus(this, options));
      });
      if (built.length === 0) {
        $.error("" + el.selector + " was not found!");
      }
      if (built.length === 1) {
        return built[0];
      }
      return built;
    },
    destroyAll: function() {
      var bus, index, _ref, _results;
      _ref = Bus._busses;
      _results = [];
      for (index in _ref) {
        bus = _ref[index];
        _results.push(bus.destroy());
      }
      return _results;
    },
    expose: function(global) {
      return global.tourbus = {
        Bus: Bus,
        Leg: Leg
      };
    }
  };

  tourbus.defaults = {
    debug: false,
    autoDepart: false,
    container: 'body',
    "class": null,
    startAt: 0,
    onDepart: function() {
      return null;
    },
    onStop: function() {
      return null;
    },
    onLegStart: function() {
      return null;
    },
    onLegEnd: function() {
      return null;
    },
    leg: {
      "class": null,
      scrollTo: null,
      scrollSpeed: 150,
      scrollContext: 100,
      orientation: 'bottom',
      align: 'left',
      width: 'auto',
      margin: 10,
      top: null,
      left: null,
      zindex: 9999,
      arrow: "50%"
    }
  };

}).call(this);

},{"./modules/bus":2,"./modules/leg":3}],2:[function(require,module,exports){
//@ sourceMappingURL=bus.map
(function() {
  var $, Bus, Leg, utils,
    __slice = [].slice;

  $ = jQuery;

  Leg = require('./leg');

  utils = require('./utils');

  module.exports = Bus = (function() {
    Bus._busses = {};

    Bus._tours = 0;

    Bus.uniqueId = function() {
      return this._tours++;
    };

    function Bus(el, options) {
      this.options = options;
      this.id = this.constructor.uniqueId();
      this.elId = "tourbus-" + this.id;
      this.constructor._busses[this.id] = this;
      this.$original = $(el);
      this.rawData = this.$original.data();
      this.$container = $(utils.dataProp(this.rawData.container, this.options.container));
      this.$original.data({
        tourbus: this
      });
      this.currentLegIndex = null;
      this.legs = [];
      this.legEls = this.$original.children('li');
      this.totalLegs = this.legEls.length;
      this._configureElement();
      this._setupEvents();
      if (utils.dataProp(this.rawData.autoDepart, this.options.autoDepart)) {
        this.$original.trigger('depart.tourbus');
      }
      this._log('built tourbus with el', el.toString(), 'and options', this.options);
    }

    Bus.prototype.depart = function() {
      this.running = true;
      this.options.onDepart(this);
      this._log('departing', this);
      this.currentLegIndex = utils.dataProp(this.rawData.startAt, this.options.startAt);
      return this.showLeg();
    };

    Bus.prototype.stop = function() {
      if (!this.running) {
        return;
      }
      $.each(this.legs, $.proxy(this.hideLeg, this));
      this.currentLegIndex = null;
      this.options.onStop(this);
      return this.running = false;
    };

    Bus.prototype.on = function(event, selector, fn) {
      return this.$container.on(event, selector, fn);
    };

    Bus.prototype.currentLeg = function() {
      if (this.currentLegIndex === null) {
        return null;
      }
      return this.legs[this.currentLegIndex];
    };

    Bus.prototype.buildLeg = function(i) {
      var $legEl, data, leg;
      $legEl = $(this.legEls[i]);
      data = $legEl.data();
      this.legs[i] = leg = new Leg({
        bus: this,
        original: $legEl,
        target: data.el || 'body',
        index: i,
        rawData: data
      });
      leg.render();
      this.$el.append(leg.$el);
      leg._position();
      leg.hide();
      return leg;
    };

    Bus.prototype.showLeg = function(index) {
      var leg, preventDefault;
      if (index == null) {
        index = this.currentLegIndex;
      }
      leg = this.legs[index] || this.buildLeg(index);
      this._log('showLeg:', leg);
      preventDefault = this.options.onLegStart(leg, this);
      if (preventDefault !== false) {
        leg.show();
      }
      if (++index < this.totalLegs && !this.legs[index]) {
        return this.buildLeg(index);
      }
    };

    Bus.prototype.hideLeg = function(index) {
      var leg, preventDefault;
      if (index == null) {
        index = this.currentLegIndex;
      }
      leg = this.legs[index];
      if (leg && leg.visible) {
        this._log('hideLeg:', leg);
        preventDefault = this.options.onLegEnd(leg, this);
        if (preventDefault !== false) {
          leg.hide();
        }
      }
      if (--index > 0 && !this.legs[index]) {
        return this.buildLeg(index);
      }
    };

    Bus.prototype.repositionLegs = function() {
      return $.each(this.legs, function() {
        return this.reposition();
      });
    };

    Bus.prototype.next = function() {
      this.hideLeg();
      this.currentLegIndex++;
      if (this.currentLegIndex > this.totalLegs - 1) {
        return this.$original.trigger('stop.tourbus');
      } else {
        return this.showLeg();
      }
    };

    Bus.prototype.prev = function(cb) {
      this.hideLeg();
      this.currentLegIndex--;
      if (this.currentLegIndex < 0) {
        return this.$original.trigger('stop.tourbus');
      } else {
        return this.showLeg();
      }
    };

    Bus.prototype.destroy = function() {
      $.each(this.legs, function() {
        return this.destroy();
      });
      this.legs = [];
      delete this.constructor._busses[this.id];
      this._teardownEvents();
      this.$original.removeData('tourbus');
      return this.$el.remove();
    };

    Bus.prototype._configureElement = function() {
      this.$el = $("<div class='tourbus-container'></div>");
      this.el = this.$el[0];
      this.$el.attr({
        id: this.elId
      });
      this.$el.addClass(utils.dataProp(this.rawData["class"], this.options["class"]));
      return this.$container.append(this.$el);
    };

    Bus.prototype._log = function() {
      if (!utils.dataProp(this.rawData.debug, this.options.debug)) {
        return;
      }
      return console.log.apply(console, ["TOURBUS " + this.id + ":"].concat(__slice.call(arguments)));
    };

    Bus.prototype._setupEvents = function() {
      this.$original.on('depart.tourbus', $.proxy(this.depart, this));
      this.$original.on('stop.tourbus', $.proxy(this.stop, this));
      this.$original.on('next.tourbus', $.proxy(this.next, this));
      return this.$original.on('prev.tourbus', $.proxy(this.prev, this));
    };

    Bus.prototype._teardownEvents = function() {
      return this.$original.off('.tourbus');
    };

    return Bus;

  })();

}).call(this);

},{"./leg":3,"./utils":4}],3:[function(require,module,exports){
//@ sourceMappingURL=leg.map
(function() {
  var $, Leg, utils, _addRule;

  $ = jQuery;

  utils = require('./utils');

  module.exports = Leg = (function() {
    function Leg(options) {
      this.options = options;
      this.$original = this.options.original;
      this.bus = this.options.bus;
      this.rawData = this.options.rawData;
      this.index = this.options.index;
      this.$target = $(this.options.target);
      this.id = "" + this.bus.id + "-" + this.options.index;
      this.elId = "tourbus-leg-" + this.id;
      this.visible = false;
      if (this.$target.length === 0) {
        throw "" + this.$target.selector + " is not an element!";
      }
      this.content = this.$original.html();
      this._setupOptions();
      this._configureElement();
      this._configureTarget();
      this._configureScroll();
      this._setupEvents();
      this.bus._log("leg " + this.index + " made with options", this.options);
    }

    Leg.prototype.render = function() {
      var arrowClass, html;
      arrowClass = this.options.orientation === 'centered' ? '' : 'tourbus-arrow';
      this.$el.addClass(" " + arrowClass + " tourbus-arrow-" + this.options.orientation + " ");
      html = "<div class='tourbus-leg-inner'>\n  " + this.content + "\n</div>";
      this.$el.css({
        width: this.options.width,
        zIndex: this.options.zindex
      }).html(html);
      return this;
    };

    Leg.prototype.destroy = function() {
      this.$el.remove();
      return this._teardownEvents();
    };

    Leg.prototype.reposition = function() {
      this._configureTarget();
      return this._position();
    };

    Leg.prototype._position = function() {
      var css, keys, rule, selector;
      if (this.options.orientation !== 'centered') {
        rule = {};
        keys = {
          top: 'left',
          bottom: 'left',
          left: 'top',
          right: 'top'
        };
        if (typeof this.options.arrow === 'number') {
          this.options.arrow += 'px';
        }
        rule[keys[this.options.orientation]] = this.options.arrow;
        selector = "#" + this.elId + ".tourbus-arrow";
        this.bus._log("adding rule for " + this.elId, rule);
        _addRule("" + selector + ":before, " + selector + ":after", rule);
      }
      css = this._offsets();
      this.bus._log('setting offsets on leg', css);
      return this.$el.css(css);
    };

    Leg.prototype.show = function() {
      this.visible = true;
      this.$el.css({
        visibility: 'visible',
        opacity: 1.0,
        zIndex: this.options.zindex
      });
      return this.scrollIntoView();
    };

    Leg.prototype.hide = function() {
      this.visible = false;
      if (this.bus.options.debug) {
        return this.$el.css({
          visibility: 'visible',
          opacity: 0.4,
          zIndex: 0
        });
      } else {
        return this.$el.css({
          visibility: 'hidden'
        });
      }
    };

    Leg.prototype.scrollIntoView = function() {
      var scrollTarget;
      if (!this.willScroll) {
        return;
      }
      scrollTarget = utils.dataProp(this.options.scrollTo, this.$el);
      this.bus._log('scrolling to', scrollTarget, this.scrollSettings);
      return $.scrollTo(scrollTarget, this.scrollSettings);
    };

    Leg.prototype._setupOptions = function() {
      var dataProps, globalOptions, prop, _i, _len, _results;
      globalOptions = this.bus.options.leg;
      dataProps = ['class', 'top', 'left', 'scrollTo', 'scrollSpeed', 'scrollContext', 'margin', 'arrow', 'align', 'width', 'zindex', 'orientation'];
      _results = [];
      for (_i = 0, _len = dataProps.length; _i < _len; _i++) {
        prop = dataProps[_i];
        _results.push(this.options[prop] = utils.dataProp(this.rawData[prop], globalOptions[prop]));
      }
      return _results;
    };

    Leg.prototype._configureElement = function() {
      this.$el = $("<div class='tourbus-leg'></div>");
      this.el = this.$el[0];
      this.$el.attr({
        id: this.elId
      });
      this.$el.addClass(this.options["class"]);
      return this.$el.css({
        zIndex: this.options.zindex
      });
    };

    Leg.prototype._setupEvents = function() {
      this.$el.on('click', '.tourbus-next', $.proxy(this.bus.next, this.bus));
      this.$el.on('click', '.tourbus-prev', $.proxy(this.bus.prev, this.bus));
      return this.$el.on('click', '.tourbus-stop', $.proxy(this.bus.stop, this.bus));
    };

    Leg.prototype._teardownEvents = function() {
      return this.$el.off('click');
    };

    Leg.prototype._configureTarget = function() {
      this.targetOffset = this.$target.offset();
      if (utils.dataProp(this.options.top, false)) {
        this.targetOffset.top = this.options.top;
      }
      if (utils.dataProp(this.options.left, false)) {
        this.targetOffset.left = this.options.left;
      }
      this.targetWidth = this.$target.outerWidth();
      return this.targetHeight = this.$target.outerHeight();
    };

    Leg.prototype._configureScroll = function() {
      this.willScroll = $.fn.scrollTo && this.options.scrollTo !== false;
      return this.scrollSettings = {
        offset: -this.options.scrollContext,
        easing: 'linear',
        axis: 'y',
        duration: this.options.scrollSpeed
      };
    };

    Leg.prototype._offsets = function() {
      var dimension, elHalf, elHeight, elWidth, offsets, targetHalf, targetHeightOverride, validOrientations;
      elHeight = this.$el.height();
      elWidth = this.$el.width();
      offsets = {};
      switch (this.options.orientation) {
        case 'centered':
          targetHeightOverride = $(window).height();
          offsets.top = this.options.top;
          if (!utils.dataProp(offsets.top, false)) {
            offsets.top = (targetHeightOverride / 2) - (elHeight / 2);
          }
          offsets.left = (this.targetWidth / 2) - (elWidth / 2);
          break;
        case 'left':
          offsets.top = this.targetOffset.top;
          offsets.left = this.targetOffset.left - elWidth - this.options.margin;
          break;
        case 'right':
          offsets.top = this.targetOffset.top;
          offsets.left = this.targetOffset.left + this.targetWidth + this.options.margin;
          break;
        case 'top':
          offsets.top = this.targetOffset.top - elHeight - this.options.margin;
          offsets.left = this.targetOffset.left;
          break;
        case 'bottom':
          offsets.top = this.targetOffset.top + this.targetHeight + this.options.margin;
          offsets.left = this.targetOffset.left;
      }
      validOrientations = {
        top: ['left', 'right'],
        bottom: ['left', 'right'],
        left: ['top', 'bottom'],
        right: ['top', 'bottom']
      };
      if (utils.include(this.options.orientation, validOrientations[this.options.align])) {
        switch (this.options.align) {
          case 'right':
            offsets.left += this.targetWidth - elWidth;
            break;
          case 'bottom':
            offsets.top += this.targetHeight - elHeight;
        }
      } else if (this.options.align === 'center') {
        if (utils.include(this.options.orientation, validOrientations.left)) {
          targetHalf = this.targetWidth / 2;
          elHalf = elWidth / 2;
          dimension = 'left';
        } else {
          targetHalf = this.targetHeight / 2;
          elHalf = elHeight / 2;
          dimension = 'top';
        }
        if (targetHalf > elHalf) {
          offsets[dimension] += targetHalf - elHalf;
        } else {
          offsets[dimension] -= elHalf - targetHalf;
        }
      }
      return offsets;
    };

    return Leg;

  })();

  _addRule = (function(styleTag) {
    var sheet;
    styleTag.type = 'text/css';
    document.getElementsByTagName('head')[0].appendChild(styleTag);
    sheet = document.styleSheets[document.styleSheets.length - 1];
    return function(selector, css) {
      var key, propText;
      propText = $.map((function() {
        var _results;
        _results = [];
        for (key in css) {
          _results.push(key);
        }
        return _results;
      })(), function(p) {
        return "" + p + ":" + css[p];
      }).join(';');
      try {
        if (sheet.insertRule) {
          sheet.insertRule("" + selector + " { " + propText + " }", (sheet.cssRules || sheet.rules).length);
        } else {
          sheet.addRule(selector, propText);
        }
      } catch (_error) {}
    };
  })(document.createElement('style'));

}).call(this);

},{"./utils":4}],4:[function(require,module,exports){
//@ sourceMappingURL=utils.map
(function() {
  module.exports = {
    dataProp: function(possiblyFalsy, alternative) {
      if (possiblyFalsy === null || typeof possiblyFalsy === 'undefined') {
        return alternative;
      }
      return possiblyFalsy;
    },
    include: function(value, array) {
      return $.inArray(value, array || []) !== -1;
    }
  };

}).call(this);

},{}]},{},[1,2,3,4]);