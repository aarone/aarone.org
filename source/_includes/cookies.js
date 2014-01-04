(function(Cookies) {

  // http://stackoverflow.com/questions/4825683/how-do-i-create-and-read-a-value-from-cookie
  Cookies.create = function(name, value, days) {
    if (days) {
      var date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      var expires = "; expires=" + date.toGMTString();
    }
    else var expires = "";
    document.cookie = name + "=" + value + expires + "; path=/";
  }

  Cookies.get = function(name) {
    if (document.cookie.length > 0) {
      start = document.cookie.indexOf(name + "=");
      if (start != -1) {
        start = start + name.length + 1;
        end = document.cookie.indexOf(";", start);
        if (end == -1) {
          end = document.cookie.length;
        }
        return unescape(document.cookie.substring(start, end));
      }
    }
    return "";
  }
}(window.Cookies = window.Cookies || {}));

