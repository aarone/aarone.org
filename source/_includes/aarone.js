window.onload = function() {
  if(Cookies.get("skipAnimations") == 'yes') {
    return;
  } else {
    Cookies.create("skipAnimations", 'yes', 1);
    var target = document.querySelector('.ticker');
    Ticker.show({target : target});
  }
};
