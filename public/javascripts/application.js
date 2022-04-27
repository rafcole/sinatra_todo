console.log("testing from application.js")

$(function() {
  // first stab with too many loose ends to attempt for todays energy levels
  // $('#todo_delete_button').on('click', function() {
  //   console.log("heard the click")
  //   confirm("Are you sure you want to delete this list? in application.js");

  // });

  // send ajax request when delete button is clicked
  $("form.delete").submit(function(event)
    {
      // sabotage the default behavior
      event.preventDefault();
      event.stopPropagation();

      // warn the user, store as boolean
      // ideally would not use built in confirm() method
      var ok = confirm("Deleting a todo item cannot be undone. Continue?")

      // if user clicks ok
      // need to get access to params from the form
        // 'this' is set equal to the form in this scope
      // 'wrapping' the form in a jQuery object
      var form = $(this);
       
      if (ok) {
        // this.submit();
        // sending ajax request
        $.ajax({
          url: form.attr("action"),
          // http method
          method: form.attr("method")
        });
      }

    // if user clicks cancel
    // ...
  });


// look for form elements with class 'delete'
  // $("form.delete").submit(function(event)
  // {
  //   // sabotage the default behavior
  //   event.preventDefault();
  //   event.stopPropagation();

  //   // warn the user, store as boolean
  //   // ideally would not use built in confirm() method
  //   var ok = confirm("Deleting a todo item cannot be undone. Continue?")

  //   // if user clicks ok
  //   if (ok) {
  //     this.submit();
  //   }

  //   // if user clicks cancel
  //   // ...
  // });
}); 