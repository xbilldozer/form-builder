$(document).ready(function(){

    if(typeof(fieldTypes) != "undefined"){        
        // Initial state for valitadtion parameter box
        $("#form_field_validation_param").attr("disabled", true);
        
        // Handle change of validation type
        $("#field_validation").change(function(){
           toggleParamsField(this); 
        });
    }

    // Handle dates on form render
    $("input[type='text'].date_field").datepicker();

});

var toggleParamsField = function(sel){
    var selectedElementId   = $(sel).children("optgroup").children(":selected").val();
    var paramField          = $("#form_field_validation_param");
    if(fieldValidations[selectedElementId].param){
        paramField.attr("disabled", false);
        // If this is a date, toggle the datepicker.
        if(fieldValidations[selectedElementId].group == "Date"){
            if (paramField.datepicker("isDisabled")){
                paramField.datepicker("enable");
            } else{
                paramField.datepicker();
            }
        }
    } else {
        paramField.attr("disabled", true);
        paramField.datepicker("disable");
    }
};