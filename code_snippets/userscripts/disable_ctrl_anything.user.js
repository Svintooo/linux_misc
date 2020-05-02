// ==UserScript==
// @name           Disable Ctrl+anything interceptions
// @description    Stop websites from highjacking keyboard/mouse shortcuts
//
// @run-at         document-start
// @include        *
// @grant          none
// ==/UserScript==

// https://superuser.com/questions/168087/how-to-forbid-keyboard-shortcut-stealing-by-websites-in-firefox

(window.opera ? document.body : document).addEventListener('keydown', function(e) {
    // alert(e.keyCode ); //uncomment to find more keyCodes
    if (e.ctrlKey) {
        e.cancelBubble = true;
        e.stopImmediatePropagation();
    // alert("Gotcha!"); //ucomment to check if it's seeing the combo
    }
    return false;
}, !window.opera);

(window.opera ? document.body : document).addEventListener('mousedown', function(e) {
    // alert(e.keyCode ); //uncomment to find more keyCodes
    if (e.ctrlKey) {
        e.cancelBubble = true;
        e.stopImmediatePropagation();
    // alert("Gotcha!"); //ucomment to check if it's seeing the combo
    }
    return false;
}, !window.opera);
