create or replace function f_validate_from_to_datepicker (
  p_item in apex_plugin.t_page_item,
  p_plugin in apex_plugin.t_plugin,
  p_value in varchar2 )
  return apex_plugin.t_page_item_validation_result
as
  -- Variables
  l_orcl_date_format apex_application_page_items.format_mask%type; -- oracle date format
  l_date date;

  -- Other attributes
  l_other_orcl_date_format apex_application_page_items.format_mask%type;
  l_other_date date;
  l_other_label apex_application_page_items.label%type;
  l_other_item_val varchar2(255);

  -- APEX information
  l_application_id apex_applications.application_id%type := apex_application.g_flow_id;
  l_page_id apex_application_pages.page_id%type := apex_application.g_flow_step_id;

  -- Item Plugin Attributes
  l_date_picker_type apex_application_page_items.attribute_01%type := lower(p_item.attribute_02); -- from/to
  l_other_item apex_application_page_items.attribute_01%type := upper(p_item.attribute_03); -- item name of other date picker

  -- Return
  l_result apex_plugin.t_page_item_validation_result;

begin
  -- Debug information (if app is being run in debug mode)
  if apex_application.g_debug then
    apex_plugin_util.debug_page_item (
      p_plugin => p_plugin,
      p_page_item => p_item,
      p_value => p_value,
      p_is_readonly => false,
      p_is_printer_friendly => false);
  end if;

  -- If no value then nothing to validate
  if p_value is null then
    return l_result;
  end if;

  -- Check that it's a valid date
  select nvl(max(format_mask), sys_context('userenv','nls_date_format'))
  into l_orcl_date_format
  from apex_application_page_items
  where item_id = p_item.id;

  l_orcl_date_format := apex_plugin_util.replace_substitutions(p_value => l_orcl_date_format);

  if not wwv_flow_utilities.is_date (p_date => p_value, p_format => l_orcl_date_format) then
    l_result.message := '#LABEL# Invalid date';
    return l_result;
  else
    l_date := to_date(p_value, l_orcl_date_format);
  end if;

  -- Check that from/to date have valid date range
  -- Only do this for From dates

  -- At this point the date exists and is valid.
  -- Only check for "from" dates so error message appears once
  if l_date_picker_type = 'from' THEN

    if length(v(l_other_item)) > 0 then
      select nvl(max(format_mask), sys_context('userenv','nls_date_format')), max(label)
      into l_other_orcl_date_format, l_other_label
      from apex_application_page_items
      where application_id = l_application_id
        and page_id = l_page_id
        and item_name = upper(l_other_item);

      l_other_orcl_date_format := apex_plugin_util.replace_substitutions(p_value => l_other_orcl_date_format);
      l_other_item_val := v(l_other_item);

      if wwv_flow_utilities.is_date (
        p_date => l_other_item_val,
        p_format => l_other_orcl_date_format) then
        l_other_date := to_date(l_other_item_val, l_other_orcl_date_format);
      end if;

    end if;

    -- If other date is not valid or does not exist then no stop validation.
    if l_other_date is null then
      return l_result;
    end if;

    -- Can now compare min/max range.
    -- Remember "this" date is the from date. "other" date is the to date
    if l_date > l_other_date then
      l_result.message := '#LABEL# must be less than or equal to ' || l_other_label;
      l_result.display_location := apex_plugin.c_inline_in_notifiction; -- Force to display inline only
      return l_result;
    end if;

  end if; -- v_date_picker_type = from

  -- No errors
  return l_result;

end f_validate_from_to_datepicker;
