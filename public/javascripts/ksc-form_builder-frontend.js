
$(document).ready(function(){
  var fieldDependencies = $(".dependent-field");
  fieldDependencies.each(function(index, el){
    
    var dependentField    = $(el);    
    var rawDependencyData = dependentField.attr("data-fields");
    var dependencyJSON    = $.parseJSON(rawDependencyData);

    for(i=0; i < dependencyJSON.length; i++){
      var dependency = dependencyJSON[i];
      ownerField = "#form_data_" + dependency.id;
      $(ownerField).change(function(e){
        if(dependency.value.toLowerCase() == $(ownerField).val().toLowerCase()){
          // Everything is cool brah, show stuff
          dependentField.show();
        } else {
          // Update the field value so its children will disappear as well.
          dependentField.val(null);
          // Hide the field.
          dependentField.hide();
        }
      });
    }
  });
  
  $(".other_field").each(function(index,el){

    var otherField  = $(el);
    var myParent    = otherField.closest("div.input");
    var myOwner     = myParent.prev("div.input");
    
    if( myOwner.find("select").length ){
      // Is a select box
      selectBox = myOwner.find("select");
      selectBox.change(function(e){
        if($(this).val() == "other_selected"){
          myParent.removeClass("disabled");
          otherField.attr("disabled", false);
        } else {
          myParent.addClass("disabled");
          otherField.attr("disabled", true);
        }
      });
    } else if ( myOwner.find("input").length ) {
      myOwner.find("input").change(function(e){        
        if($(this).attr("checked") && $(this).val() == "other_selected"){
          myParent.removeClass("disabled");
          otherField.attr("disabled", false);
        } else {
          myParent.addClass("disabled");
          otherField.attr("disabled", true);
        }
      });
    }
    
    
    
    
  });
  
  
  
  
  
});