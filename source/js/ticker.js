(function(Ticker) {

  Ticker.show = function(options) {
    if(! 'target' in options) {
      throw "'target' element is missing in given options";
    }

    initializeStyles();
    options['charactersPerIteration'] = options['charactersPerIteration'] || 2;
    ticker(options).initialize();
  }

  function initializeStyles() {
    if(document.getElementById("tickerStyle") != null) {
      return;
    }

    var head = document.getElementsByTagName("head")[0];
    var styleElement = document.createElement("style");
    styleElement.setAttribute("id", "tickerStyle");
    styleElement.type = "text/css";
    styleElement.media = "screen";
    styleElement.innerHTML = ".tickerSource {visibility: hidden;}"
    head.appendChild(styleElement);
  };

  function isEmptyTextNode(node) {
    return node != null &&
      node.nodeType == Node.TEXT_NODE &&
      node.nodeValue.length == 0
  }

  var ticker = function(options) {
    var root = options['target'];
    var charactersPerIteration = options['charactersPerIteration'];
    var timerId = null;
    var timerInterval = 2;
    var currentSourceTargetTextNode = null;

    return {
      initialize: function() {
        initializeStyles();
        var contentToTick = root.innerHTML;
        root.innerHTML = "<div class='tickerTarget'></div><div class='tickerSource'>" + 
          contentToTick + 
          "</div>";
        this.start();
      },
      start: function() {
        var ticker = this;
        timerId = setInterval(function() {
          ticker.tick();
        }, timerInterval);
      },
      tick: function() {
        var targetElement = root.getElementsByClassName("tickerTarget")[0];
        var sourceElement = root.getElementsByClassName("tickerSource")[0];
        this.removeCursor();
        var sourceTargetToModify = this.findNextTextElementToModify(sourceElement, targetElement);

        if(sourceTargetToModify != null) {
          this.showCursor(sourceTargetToModify[1]);
          this.displayNextToken(sourceTargetToModify[0], sourceTargetToModify[1]);
        } else {
          this.showCursor(targetElement.childNodes[targetElement.childNodes.length-1])
          clearInterval(timerId);
        }
      },
      activeTextNode: function() {
        if(currentSourceTargetTextNode != null &&
           !isEmptyTextNode(currentSourceTargetTextNode[0])) {
          return currentSourceTargetTextNode;
        }
        return null;
      },
      nextToken: function(text) {
        return text.substr(0, charactersPerIteration);
      },
      remainder: function(text) {
        return text.substr(charactersPerIteration, text.length-1)
      },
      findNextTextElementToModify: function(sourceElement, targetElement) {
        if(this.activeTextNode() != null) {
          return this.activeTextNode();
        }

        if(isEmptyTextNode(sourceElement)) {
          return null;
        } else if(sourceElement.nodeType == Node.TEXT_NODE &&
                  sourceElement.nodeValue.length > 0) {

          currentSourceTargetTextNode = [sourceElement, targetElement];
          return currentSourceTargetTextNode;
        } else {
          for(var i=0; i<sourceElement.childNodes.length; i++) {
            var sourceChild = sourceElement.childNodes[i];
            var targetChild = null;

            if(isEmptyTextNode(sourceChild)) {
              continue;
            } else if(i < targetElement.childNodes.length) {
              targetChild = targetElement.childNodes[i];
            } else if(sourceChild.nodeType == Node.TEXT_NODE) {
              targetChild = document.createTextNode("");
              targetElement.appendChild(targetChild);
            } else {
              targetChild = sourceChild.cloneNode(false);
              targetChild.nodeValue = "";
              targetElement.appendChild(targetChild);
            }
            var nextToModify = this.findNextTextElementToModify(sourceChild, targetChild);
            if(nextToModify == null) {
              continue;
            } else {
              return nextToModify;
            }
          }
        }
      },
      removeCursor: function() {
        var cursorElement = document.getElementById("cursor");
        if(cursorElement != null) {
          cursorElement.parentElement.removeChild(cursorElement);
        }
      },
      showCursor: function(targetElement) {
        cursorElement = document.createElement("span");
        cursorElement.setAttribute("id", "cursor");
        cursorElement.innerHTML = " ";
        targetElement.parentNode.appendChild(cursorElement);
      },
      displayNextToken: function(sourceElement, targetElement) {
        var remainingSource = this.remainder(sourceElement.nodeValue);
        var updatedTarget = targetElement.nodeValue + this.nextToken(sourceElement.nodeValue);
        
        sourceElement.nodeValue = remainingSource;
        targetElement.nodeValue = updatedTarget;
      }
    }
  };
}(window.Ticker = window.Ticker || {}));

