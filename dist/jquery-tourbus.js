(function() {

  (function($) {
    var Leg, TourBus, uniqueId, _addRule, _dataProp, _include, _tours;
    $.fn.tourbus = function(options) {
      if (options == null) {
        options = {};
      }
      options = $.extend(true, {}, $.fn.tourbus.defaults, options);
      return this.each(function() {
        return new TourBus(this, options);
      });
    };
    $.fn.tourbus.defaults = {
      debug: false,
      autoDepart: false,
      target: 'body',
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
        scrollTo: null,
        scrollSpeed: 150,
        scrollContext: 100,
        orientation: 'bottom',
        align: 'left',
        width: 'auto',
        margin: 10,
        top: null,
        left: null,
        arrow: "50%"
      }
    };
    /* Internal
    */

    TourBus = (function() {

      function TourBus(el, options) {
        this.id = uniqueId();
        this.$target = $(options.target);
        this.$el = $(el);
        this.$el.data({
          tourbus: this
        });
        this.options = options;
        this.currentLegIndex = null;
        this.totalLegs = this.$el.find('li').length;
        this._setupEvents();
        if (this.options.autoDepart) {
          this.$el.trigger('depart.tourbus');
        }
        this._log('built tourbus with options', this.options);
      }

      TourBus.prototype.depart = function() {
        this.running = true;
        this.options.onDepart(this);
        this._log('departing');
        this.legs = this._buildLegs();
        this.currentLegIndex = this.options.startAt;
        return this.showLeg(this.currentLegIndex);
      };

      TourBus.prototype.stop = function() {
        if (!this.running) {
          return;
        }
        this.hideAllLegs();
        this.currentLegIndex = this.options.startAt;
        this.options.onStop(this);
        return this.running = false;
      };

      TourBus.prototype.on = function(event, selector, fn) {
        return this.$target.on(event, selector, fn);
      };

      TourBus.prototype.currentLeg = function() {
        if (this.currentLegIndex === null) {
          return null;
        }
        return this.legs[this.currentLegIndex];
      };

      TourBus.prototype.showLeg = function(index) {
        var leg, preventDefault;
        if (index == null) {
          index = this.currentLegIndex;
        }
        leg = this.legs[index];
        preventDefault = this.options.onLegStart(leg, this);
        if (preventDefault !== false) {
          return leg.show();
        }
      };

      TourBus.prototype.hideLeg = function(index) {
        var leg, preventDefault;
        leg = this.legs[index];
        preventDefault = this.options.onLegEnd(leg, this);
        if (preventDefault !== false) {
          return leg.hide();
        }
      };

      TourBus.prototype.hideAllLegs = function() {
        return $.each(this.legs, $.proxy(this.hideLeg, this));
      };

      TourBus.prototype.next = function() {
        this.hideAllLegs();
        this.currentLegIndex++;
        if (this.currentLegIndex > this.totalLegs - 1) {
          return this.stop();
        } else {
          return this.showLeg(this.currentLegIndex);
        }
      };

      TourBus.prototype.prev = function() {
        this.hideAllLegs();
        this.currentLegIndex--;
        if (this.currentLegIndex < 0) {
          return this.stop();
        } else {
          return this.showLeg(this.currentLegIndex);
        }
      };

      TourBus.prototype.destroy = function() {
        $.each(this.legs, function() {
          return this.destroy();
        });
        return this._teardownEvents();
      };

      TourBus.prototype._buildLegs = function() {
        var _this = this;
        if (this.legs && this.legs.length) {
          $.each(this.legs, function(_, leg) {
            return leg.destroy();
          });
        }
        return $.map(this.$el.find('li'), function(legEl, i) {
          var $legEl, data, leg;
          $legEl = $(legEl);
          data = $legEl.data();
          leg = new Leg({
            content: $legEl.html(),
            target: data.el || 'body',
            tourbus: _this,
            index: i,
            rawData: data
          });
          leg.render();
          _this.$target.append(leg.$el);
          leg.position();
          leg.hide();
          return leg;
        });
      };

      TourBus.prototype._log = function() {
        var args;
        if (!this.options.debug) {
          return;
        }
        args = new Array(arguments);
        args.unshift("TOURBUS " + this.id + ":");
        return console.log.apply(console, args);
      };

      TourBus.prototype._setupEvents = function() {
        this.$el.on('depart.tourbus', $.proxy(this.depart, this));
        this.$el.on('stop.tourbus', $.proxy(this.stop, this));
        this.$el.on('next.tourbus', $.proxy(this.next, this));
        return this.$el.on('prev.tourbus', $.proxy(this.prev, this));
      };

      TourBus.prototype._teardownEvents = function() {
        return this.$el.off('.tourbus');
      };

      return TourBus;

    })();
    Leg = (function() {

      function Leg(options) {
        this.tourbus = options.tourbus;
        this.rawData = options.rawData;
        this.content = options.content;
        this.index = options.index;
        this.options = options;
        this.$target = $(options.target);
        if (this.$target.length === 0) {
          throw "" + this.$target.selector + " is not an element!";
        }
        this._setupOptions();
        this._configureElement();
        this._configureTarget();
        this._configureScroll();
        this._setupEvents();
        this.tourbus._log("leg " + this.index + " made with options", this.options);
      }

      Leg.prototype.render = function() {
        var arrowClass, html;
        arrowClass = this.options.orientation === 'centered' ? '' : 'tourbus-arrow';
        this.$el.addClass(" " + arrowClass + " tourbus-arrow-" + this.options.orientation + " ");
        html = "<div class='tourbus-leg-inner'>\n  " + this.content + "\n</div>";
        this.$el.css({
          width: this.options.width
        }).html(html);
        return this;
      };

      Leg.prototype.destroy = function() {
        this.$el.remove();
        return this._teardownEvents();
      };

      Leg.prototype.position = function() {
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
          selector = "#" + this.id + ".tourbus-arrow";
          this.tourbus._log("adding rule for " + this.id, rule);
          _addRule("" + selector + ":before, " + selector + ":after", rule);
        }
        css = this._offsets();
        this.tourbus._log('setting offsets on leg', css);
        return this.$el.css(css);
      };

      Leg.prototype.show = function() {
        this.$el.css({
          visibility: 'visible',
          opacity: 1.0,
          zIndex: 9999
        });
        return this.scrollIntoView();
      };

      Leg.prototype.hide = function() {
        if (this.tourbus.options.debug) {
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
        if (!($.fn.scrollTo && !isNaN(this.options.scrollSpeed))) {
          return;
        }
        if (this.options.scrollTo === false) {
          return;
        }
        scrollTarget = _dataProp(this.options.scrollTo, this.$el);
        this.tourbus._log('scrolling to', scrollTarget, this.scrollSettings);
        return $.scrollTo(scrollTarget, this.scrollSettings);
      };

      Leg.prototype._setupOptions = function() {
        var globalOptions;
        globalOptions = this.tourbus.options.leg;
        this.options.top = _dataProp(this.rawData.top, globalOptions.top);
        this.options.left = _dataProp(this.rawData.left, globalOptions.left);
        this.options.scrollTo = _dataProp(this.rawData.scrollTo, globalOptions.scrollTo);
        this.options.scrollSpeed = _dataProp(this.rawData.scrollSpeed, globalOptions.scrollSpeed);
        this.options.scrollContext = _dataProp(this.rawData.scrollContext, globalOptions.scrollContext);
        this.options.margin = _dataProp(this.rawData.margin, globalOptions.margin);
        this.options.arrow = this.rawData.arrow || globalOptions.arrow;
        this.options.align = this.rawData.align || globalOptions.align;
        this.options.width = this.rawData.width || globalOptions.width;
        return this.options.orientation = this.rawData.orientation || globalOptions.orientation;
      };

      Leg.prototype._configureElement = function() {
        this.id = "tourbus-leg-id-" + this.tourbus.id + "-" + this.options.index;
        this.$el = $("<div class='tourbus-leg'></div>");
        this.el = this.$el[0];
        this.$el.attr({
          id: this.id
        });
        return this.$el.css({
          zIndex: 9999
        });
      };

      Leg.prototype._setupEvents = function() {
        this.$el.on('click', '.tourbus-next', $.proxy(this.tourbus.next, this.tourbus));
        this.$el.on('click', '.tourbus-prev', $.proxy(this.tourbus.prev, this.tourbus));
        return this.$el.on('click', '.tourbus-stop', $.proxy(this.tourbus.stop, this.tourbus));
      };

      Leg.prototype._teardownEvents = function() {
        return this.$el.off('click');
      };

      Leg.prototype._configureTarget = function() {
        this.targetOffset = this.$target.offset();
        if (_dataProp(this.options.top, false)) {
          this.targetOffset.top = this.options.top;
        }
        if (_dataProp(this.options.left, false)) {
          this.targetOffset.left = this.options.left;
        }
        this.targetWidth = this.$target.outerWidth();
        return this.targetHeight = this.$target.outerHeight();
      };

      Leg.prototype._configureScroll = function() {
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
            if (!_dataProp(offsets.top, false)) {
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
        if (_include(this.options.orientation, validOrientations[this.options.align])) {
          switch (this.options.align) {
            case 'right':
              offsets.left += this.targetWidth - elWidth;
              break;
            case 'bottom':
              offsets.top += this.targetHeight - elHeight;
          }
        } else if (this.options.align === 'center') {
          if (_include(this.options.orientation, validOrientations.left)) {
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

      Leg.prototype._debugHtml = function() {
        var debuggableOptions;
        debuggableOptions = $.extend(true, {}, this.options);
        delete debuggableOptions.tourbus;
        delete debuggableOptions.content;
        delete debuggableOptions.target;
        return "<small>\n  This leg built with:\n  <pre>" + (JSON.stringify(debuggableOptions, void 0, 2)) + "</pre>\n</small>";
      };

      return Leg;

    })();
    _tours = 0;
    uniqueId = function() {
      return _tours++;
    };
    _dataProp = function(possiblyFalsy, alternative) {
      if (possiblyFalsy === null || typeof possiblyFalsy === 'undefined') {
        return alternative;
      }
      return possiblyFalsy;
    };
    _include = function(value, array) {
      return (array || []).indexOf(value) !== -1;
    };
    return _addRule = (function(styleTag) {
      var sheet;
      sheet = document.head.appendChild(styleTag).sheet;
      return function(selector, css) {
        var propText;
        propText = $.map(Object.keys(css), function(p) {
          return "" + p + ":" + css[p];
        }).join(';');
        return sheet.insertRule("" + selector + " { " + propText + " }", sheet.cssRules.length);
      };
    })(document.createElement('style'));
  })(jQuery);

}).call(this);
