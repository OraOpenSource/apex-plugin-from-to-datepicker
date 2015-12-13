create or replace function f_render_from_to_datepicker (
  p_item in apex_plugin.t_page_item,
  p_plugin in apex_plugin.t_plugin,
  p_value in varchar2,
  p_is_readonly in boolean,
  p_is_printer_friendly in boolean )
  return apex_plugin.t_page_item_render_result

as
  -- APEX information
  l_application_id apex_applications.application_id%type := apex_application.g_flow_id;
  l_page_id apex_application_pages.page_id%type := apex_application.g_flow_step_id;

  -- Main plug-in variables
  l_result apex_plugin.t_page_item_render_result; -- Result object to be returned
  l_page_item_name varchar2(100);  -- Item name (different than ID)
  l_html varchar2(4000); -- Used for temp HTML

  -- Application Plugin Attributes
  l_button_img apex_appl_plugins.attribute_01%type := p_plugin.attribute_01;

  -- Item Plugin Attributes
  l_show_on apex_application_page_items.attribute_01%type := lower(p_item.attribute_01); -- When to show date picker. Options: focus, button, both
  l_date_picker_type apex_application_page_items.attribute_01%type := lower(p_item.attribute_02); -- from or to
  -- Note: If this cahnages from attribute 03 the need to modify validations below
  l_other_item apex_application_page_items.attribute_01%type := upper(p_item.attribute_03); -- Name of other date picker item


  -- Other variables
  -- Oracle date formats differen from JS date formats
  l_orcl_date_format_mask p_item.format_mask%type; -- Oracle date format: http://www.techonthenet.com/oracle/functions/to_date.php
  l_js_date_format_mask p_item.format_mask%type; -- JS date format: http://docs.jquery.com/UI/Datepicker/formatDate
  l_other_js_date_format_mask apex_application_page_items.format_mask%type; -- This is the other datepicker's JS date format. Required since it may not contain the same format mask as this date picker


  l_err_msg varchar2(255);

begin
  -- Debug information (if app is being run in debug mode)
  if apex_application.g_debug then
    apex_plugin_util.debug_page_item (
      p_plugin => p_plugin,
      p_page_item => p_item,
      p_value => p_value,
      p_is_readonly => p_is_readonly,
      p_is_printer_friendly => p_is_printer_friendly);
  end if;

  -- handle read only and printer friendly
  if p_is_readonly or p_is_printer_friendly then
    -- omit hidden field if necessary
    apex_plugin_util.print_hidden_if_readonly (
      p_item_name => p_item.name,
      p_value => p_value,
      p_is_readonly => p_is_readonly,
      p_is_printer_friendly => p_is_printer_friendly);

    -- omit display span with the value
    apex_plugin_util.print_display_only (
      p_item_name => p_item.name,
      p_display_value => p_value,
      p_show_line_breaks => false,
      p_escape => true, -- this is recommended to help prevent XSS
      p_attributes => p_item.element_attributes);
  else
    -- Not read only
    -- Get name. Used in the "name" form element attribute which is different than the "id" attribute
    l_page_item_name := apex_plugin.get_input_name_for_page_item (p_is_multi_value => false);

    -- Validations (configuration)
    select
      case
        -- Correspending date item must be different than self (Issue $5)
        when pi_org.item_name = pi_other.item_name then
          '%ERROR_PREFIX% "' || pa_ci.prompt || '" must be a different page item (can''t be the same as self).'
        -- Other item should exist
        when pi_other.item_name is null then
          '%ERROR_PREFIX% "' || pa_ci.prompt || '" item (%OTHER_ITEM_NAME%) does not exist'
        -- Check that corresponding item is also from/to date picker
        when pi_org.display_as_code != pi_other.display_as_code then
          '%ERROR_PREFIX% %OTHER_ITEM_NAME% must be of same type (' || pi_org.display_as || ')'
        -- Check that corresponding item points to this one
        when nvl(pi_other.attribute_03,'a') != pi_org.item_name then
          '%ERROR_PREFIX% "' || pa_ci.prompt || '" for %OTHER_ITEM_NAME% is not set to %ITEM_NAME%'
        else
          null
      end err_msg
    into
      l_err_msg
    from
      apex_application_page_items pi_org,
      apex_application_page_items pi_other,
      apex_appl_plugin_attributes pa_ci -- corresponding item attribute
    where 1=1
      and pi_org.application_id = apex_application.g_flow_id
      and pi_org.item_name = p_item.name
      and pi_org.application_id = pi_other.application_id(+)
      and pi_org.attribute_03 = pi_other.item_name(+)
      -- Attributes
      and pa_ci.application_id = pi_org.application_id
      and upper(pi_org.display_as_code) = upper('PLUGIN_' || pa_ci.plugin_name)
      and pa_ci.attribute_sequence = 3
    ;

    if l_err_msg is not null then
      l_err_msg := replace(l_err_msg, '%ERROR_PREFIX%', '%ITEM_NAME% Configuration Error:');
      l_err_msg := replace(l_err_msg, '%ITEM_NAME%', p_item.name);
      l_err_msg := replace(l_err_msg, '%OTHER_ITEM_NAME%', l_other_item);

      raise_application_error(-20001, l_err_msg);
    end if;



    -- SET VALUES

    -- If no format mask is defined use the system level date format
    l_orcl_date_format_mask :=
      nvl(
        apex_plugin_util.replace_substitutions(p_value => p_item.format_mask),
        sys_context('userenv','nls_date_format'));

    -- Convert the Oracle date format to JS format mask
    l_js_date_format_mask := wwv_flow_utilities.get_javascript_date_format(p_format => l_orcl_date_format_mask);

    -- Get the corresponding date picker's format mask
    select
      wwv_flow_utilities.get_javascript_date_format(
        p_format =>
          nvl(
            apex_plugin_util.replace_substitutions(p_value => max(format_mask)), sys_context('userenv','nls_date_format')))
    into l_other_js_date_format_mask
    from apex_application_page_items
    where application_id = l_application_id
      and page_id = l_page_id
      and item_name = upper(l_other_item);

    -- OUTPUT

    -- Print input element
    l_html := '<input type="text" id="%ID%" name="%NAME%" value="%VALUE%" autocomplete="off" size="%SIZE%" maxlength="%MAX_LENGTH%">';
    l_html := replace(l_html, '%ID%', p_item.name);
    l_html := replace(l_html, '%NAME%', l_page_item_name);
    l_html := replace(l_html, '%VALUE%', p_value);
    l_html := replace(l_html, '%SIZE%', p_item.element_width);
    l_html := replace(l_html, '%MAX_LENGTH%', p_item.element_max_length);
    sys.htp.p(l_html);

    -- Initialize the fromToDatePicker
    l_html :=
    '$("#%NAME%").oosFromToDatePicker({
      correspondingDatePicker: {
        %OTHER_DATE_FORMAT%
        %ID%
        %VALUE_END_ELEMENT%
      },
      datePickerAttrs: {
        %DATE_FORMAT%
        %SHOW_ON_END_ELEMENT%
      },
      %DATE_PICKER_TYPE_END_ELEMENT%
    });';
    l_html := replace(l_html, '%NAME%', p_item.name);
    l_html := replace(l_html, '%OTHER_DATE_FORMAT%', apex_javascript.add_attribute('dateFormat',  apex_escape.html(l_other_js_date_format_mask)));
    l_html := replace(l_html, '%DATE_FORMAT%', apex_javascript.add_attribute('dateFormat',  apex_escape.html(l_js_date_format_mask)));
    l_html := replace(l_html, '%ID%', apex_javascript.add_attribute('id', l_other_item));
    l_html := replace(l_html, '%VALUE_END_ELEMENT%', apex_javascript.add_attribute('value',  apex_escape.html(v(l_other_item)), false, false));
    l_html := replace(l_html, '%SHOW_ON_END_ELEMENT%', apex_javascript.add_attribute('showOn',  apex_escape.html(l_show_on), false, false));
    l_html := replace(l_html, '%DATE_PICKER_TYPE_END_ELEMENT%', apex_javascript.add_attribute('datePickerType',  apex_escape.html(l_date_picker_type), false, false));

    apex_javascript.add_onload_code (p_code => l_html);

    -- Tell apex that this field is navigable
    l_result.is_navigable := false;

  end if; -- f_render_from_to_datepicker

  return l_result;
end f_render_from_to_datepicker;
