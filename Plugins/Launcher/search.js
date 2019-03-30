
/*
===== Example =====
var s = new Search(document.getElementById("foo"));
s.onsubmit = (string value) => {
  s.setValue('');
  s.setSuggestions([]);
  // Do things.
};
s.onchange = (string value) => {
  s.setSuggestions([
    {'value': 'A', 'html': value + 'A'},
    {'value': 'B', 'html': value + 'B'}
  ]);
};

===== Styling =====
The default styling is intentionally very minimal.
You can add your own style by adding a class to the given div:

var div = document.getElementById("foo");
var s = new Search(div);
div.classList.add('bar');

div.bar > input { ... }
div.bar > table { ... }
div.bar > table > tbody > tr { ... }

*/


function Search(div) {
  var this_input = document.createElement('input');
  disableSmartPunctuationForTextInput(this_input);
  this_input.spellcheck = false;
  this_input.addEventListener('input', (event) => {
    this.onchange(this_input.value);
  });
  var handleEnter = () => {
    if (this_selectedIndex == -1) {
      this.onsubmit(this_input.value);
    } else {
      this.onsubmit(this_suggestionsValues[this_selectedIndex]);
    }
  };
  this_input.addEventListener('keydown', (event) => {
    if (event.keyCode == 13) {
      // Enter
      handleEnter();
    } else if (event.keyCode == 38) {
      // Up
      if (this_selectedIndex == -1) {
        var tbody = this_table.children[0];
        setSelectedIndex(tbody.children.length - 1);
      } else {
        setSelectedIndex(this_selectedIndex - 1);
      }
    } else if (event.keyCode == 40) {
      // Down
      var tbody = this_table.children[0];
      if (this_selectedIndex == tbody.children.length - 1) {
        setSelectedIndex(-1);
      } else {
        setSelectedIndex(this_selectedIndex+1);
      }
    }
  });
  div.appendChild(this_input);

  var this_table = document.createElement('table');
  div.appendChild(this_table);

  var this_selectedIndex = -1;
  var setSelectedIndex = (newIndex) => {
    var tbody = this_table.children[0];
    if (this_selectedIndex != -1) {
      tbody.children[this_selectedIndex].classList.remove('selected');
    }
    this_selectedIndex = newIndex;
    if (this_selectedIndex != -1) {
      tbody.children[this_selectedIndex].classList.add('selected');
    }
  }

  var this_suggestionsValues = [];
  isElementPrimaryTR = (element) => {
    if (element.tagName != 'TR') return false;
    var tbody = this_table.children[0];
    for (var i = 0; i < tbody.children.length; ++i) {
      if (tbody.children[i] == element) return true;
    }
    return false;
  }
  var rowFromEvent = (event) => {
    var el = event.target;
    while (!isElementPrimaryTR(el)) {
      el = el.parentElement;
      if (el === null) return null;
    }
    return el;
  }
  this.setSuggestions = (newSuggestions) => {
    setSelectedIndex(-1);
    this_suggestionsValues = [];
    if (newSuggestions === null) {
      this_table.innerHTML = '';
      return;
    }
    var tbody = document.createElement('tbody');
    for (var i = 0; i < newSuggestions.length; ++i) {
      var tr = document.createElement('tr');
      var td = document.createElement('td');
      td.innerHTML = newSuggestions[i]['html'];
      this_suggestionsValues.push(newSuggestions[i]['value']);
      tr.appendChild(td);
      tr.addEventListener('mouseenter', (event) => {
        var targetRow = rowFromEvent(event);
        for (var j = 0; j < tbody.children.length; ++j) {
          if (tbody.children[j] == targetRow) {
            setSelectedIndex(j);
            break;
          }
        }
      });
      tr.addEventListener('click', (event) => {
        var tbody = this_table.children[0];
        var targetRow = rowFromEvent(event);
        for (var j = 0; j < tbody.children.length; ++j) {
          if (tbody.children[j] == targetRow) {
            setSelectedIndex(j);
            handleEnter();
            break;
          }
        }
      })
      tbody.appendChild(tr);
    }
    this_table.innerHTML = '';
    setSelectedIndex(-1);
    this_table.appendChild(tbody);
  };
  this.setValue = (newValue) => {
    this_input.value = newValue;
  };
  this.input = () => {
    return this_input;
  };
}
