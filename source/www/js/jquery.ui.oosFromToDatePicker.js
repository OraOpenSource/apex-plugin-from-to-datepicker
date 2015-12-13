/**
 * OraOpenSource FromTo Date Picker for APEX
 * Plug-in Type: Item
 * Summary: Handles automatically changing the min/max dates
 *
 * Depends:
 *  jquery.ui.datepicker.js
 *
 * Special thanks to Dan McGhan (http://www.danielmcghan.us) for his JavaScript help
 *
 * Version:
 *  1.0.1: Fixed IE 7 issue which had extra comma after several JSON objects causing a "Expected identifier String or Number" error message
 *  1.0.0: Initial
 *  2.0.0: Migrate from ClariFit plugin to OraOpenSource and built in APEX 5.0
 *
 * ^^^ Contact information ^^^
 * Developed by OraOpenSource
 * http://www.oraopensource.com
 * martin@clarifit.com
 *
 * ^^^ License ^^^
 * Licensed Under: The MIT License (MIT) - http://www.opensource.org/licenses/gpl-3.0.html
 *
 * @author Martin Giffy D'Souza - http://www.talkapex.com
 */
(function($, widget){
  $.widget('ui.oosFromToDatePicker', {
    // default options
    options: {
      //Information about the other date picker
      correspondingDatePicker: {
        dateFormat: '',  //Need other date format since it may not be the same as current date format
        id: '',
        value: ''
        }, //Value during page load
      //Options for this date picker
      datePickerAttrs: {
        autoSize: false, // Future: see issue #1
        buttonText: '<span class="a-Icon icon-calendar"></span><span class="u-VisuallyHidden">Popup Calendar: Subscriptions in effect From<span></span></span>',
        changeMonth: false,
        changeYear: false,
        dateFormat: 'mm/dd/yy', //Default date format. Will be set by plugin
        showAnim: '', //By default disable animation
        showOn: 'both'},
      datePickerType: '', //from or to
      buttonClasses: 'a-Button a-Button--calendar' //CSS Classes to add to buttons
    },

    /**
     * Init function. This function will be called each time the widget is referenced with no parameters
     */
    _init: function(){
      var uiw = this;

      //For this plug-in there's no code required for this section
      //Left here for demonstration purposes
      apex.debug.log(uiw._scope, '_init', uiw);
    }, //_init

    /**
     * Set private widget varables
     */
    _setWidgetVars: function(){
      var uiw = this;

      uiw._scope = 'ui.oosFromToDatePicker'; //For debugging

      uiw._values = {
        shortYearCutoff: 30 //roll over year
      };

      uiw._elements = {
        $otherDate: null,
        $elementObj: $(uiw.element)
      };

    }, //_setWidgetVars

    /**
     * Create function: Called the first time widget is associated to the object
     * Does all the required setup etc and binds change event
     */
    _create: function(){
      var uiw = this;

      uiw._setWidgetVars();

      var consoleGroupName = uiw._scope + '_create';
      // apex.debug.groupCollapsed(consoleGroupName);
      apex.debug.log('this:', uiw);
      apex.debug.log('element:', uiw.element[0]);

      var
        otherDate,
        minDate = '',
        maxDate = ''
      ;

      //Get the initial min/max dates restrictions
      //If other date is not well formmated an exception will be raise
      try{
        otherDate = uiw.options.correspondingDatePicker.value != '' ? $.datepicker.parseDate(uiw.options.correspondingDatePicker.dateFormat, uiw.options.correspondingDatePicker.value, {shortYearCutoff: uiw._values.shortYearCutoff}) : ''
        minDate = uiw.options.datePickerType  == 'to' ? otherDate : '',
        maxDate = uiw.options.datePickerType == 'from' ? otherDate : ''
        uiw._elements.$otherDate = $('#' + uiw.options.correspondingDatePicker.id);
      }
      catch (err){
        apex.debug.warn('Invalid Other Date', uiw);
      }

      //Help prevent invalid configurations (Issue #5)
      if (uiw._elements.$otherDate.attr('id') == uiw._elements.$elementObj.attr('id')){
        var errMsg = uiw.widgetEventPrefix + ': ERROR - APEX Item Plugin setting - Corresponding Date Item cant be self.';

        window.alert(errMsg);
        apex.debug.error(
          '%c' + errMsg + ' See https://github.com/OraOpenSource/apex-plugin-from-to-datepicker/issues/5',
          'background: red; color: yellow; font-size: xx-large'
        );
      }


      //Register DatePicker
      uiw._elements.$elementObj.datepicker({
        autoSize: uiw.options.datePickerAttrs.autoSize,
        buttonText: uiw.options.datePickerAttrs.buttonText,
        changeMonth: uiw.options.datePickerAttrs.changeMonth,
        changeYear: uiw.options.datePickerAttrs.changeYear,
        dateFormat: uiw.options.datePickerAttrs.dateFormat,
        minDate: minDate,
        maxDate: maxDate,
        showAnim: uiw.options.datePickerAttrs.showAnim,
        showOn: uiw.options.datePickerAttrs.showOn,
        //Events
        onSelect: function(dateText, inst){
          var
            extraParams = { dateText: dateText, inst: inst }
          ;
          uiw._elements.$elementObj.trigger('change'); // Need to trigger change event so that other date is updated
          // #2
          // uiw._elements.$elementObj.trigger('oosfromtodatepickeronchange', extraParams); // Trigger Plugin Event: pluginEventOnSelect if something is listening to it
        }
      });

      uiw._elements.$elementObj.on('change.' + uiw.widgetEventPrefix, function(){
        // Sets the min/max date for related date element
        // Since this function is being called as an event "this" refers to the DOM object and not the widget "this" object
        // uiw references the UI Widget "this"
        apex.debug.log(uiw._scope, 'onchange', this);

        var
          optionToChange = uiw.options.datePickerType == 'from' ? 'minDate' : 'maxDate',
          selfDate
        ;

        try {
          selfDate = $.datepicker.parseDate(
            uiw.options.datePickerAttrs.dateFormat,
            uiw._elements.$elementObj.val(),
            {shortYearCutoff: 30});

          uiw._elements.$otherDate.datepicker('option', optionToChange,selfDate); //Set the min/max date information for related date option

          //Need to re-add the button classes
          uiw._elements.$otherDate.next('button').addClass(uiw.options.buttonClasses);
        } catch (e) {
          // Future: Add optional alert message (currently APEX doesn't offer this nor does it suppress a change event)
          apex.debug.error(e);
        }

      }); //on

      // Only add button class if button is to show up
      if (uiw.options.datePickerAttrs.showOn === 'both' || uiw.options.datePickerAttrs.showOn === 'button') {
        uiw._elements.$elementObj.next('button').addClass(uiw.options.buttonClasses);
      }

      // Register apex.item callbacks
      // Examples copied from widget.datepicker.js
      widget.initPageItem(uiw.element[0].id, {
        enable : function() {
          uiw._elements.$elementObj
            .datepicker('enable') // call native jQuery UI enable
            .removeClass('apex_disabled'); // remove disabled class
        },
        disable : function() {
          uiw._elements.$elementObj
            .datepicker('disable') // call native jQuery UI disable
            .addClass('apex_disabled'); // add disabled class to ensure value is not POSTed
        }
      });

      // apex.debug.groupEnd(consoleGroupName);
    },//_create

    /**
     * Removes all functionality associated with the oosFromToDatePicker
     * Will remove the change event as well
     * Odds are this will not be called from APEX.
     */
    destroy: function() {
      var uiw = this;

      apex.debug.log(uiw._scope, 'destroy', uiw);
      $.Widget.prototype.destroy.apply(uiw, arguments); // default destroy
      // unregister datepicker
      $(uiw.element).datepicker('destroy');
    }//destroy
  }); //ui.oosFromToDatePicker

})(apex.jQuery, apex.widget);
