set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_050000 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2013.01.01'
,p_release=>'5.0.2.00.07'
,p_default_workspace_id=>4101074133915614
,p_default_application_id=>160
,p_default_owner=>'GIFFY'
);
end;
/
prompt --application/ui_types
begin
null;
end;
/
prompt --application/shared_components/plugins/item_type/com_clarifit_fromtodatepicker
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(23917661801437229060)
,p_plugin_type=>'ITEM TYPE'
,p_name=>'COM.CLARIFIT.FROMTODATEPICKER'
,p_display_name=>'OraOpenSource From To Date Picker'
,p_supported_ui_types=>'DESKTOP'
,p_image_prefix=>''
,p_javascript_file_urls=>'#PLUGIN_FILES#js/jquery.ui.oosFromToDatePicker.js'
,p_plsql_code=>wwv_flow_utilities.join(wwv_flow_t_varchar2(
'function f_render_from_to_datepicker (',
'  p_item in apex_plugin.t_page_item,',
'  p_plugin in apex_plugin.t_plugin,',
'  p_value in varchar2,',
'  p_is_readonly in boolean,',
'  p_is_printer_friendly in boolean )',
'  return apex_plugin.t_page_item_render_result',
'',
'as',
'  -- APEX information',
'  l_application_id apex_applications.application_id%type := apex_application.g_flow_id;',
'  l_page_id apex_application_pages.page_id%type := apex_application.g_flow_step_id;',
'',
'  -- Main plug-in variables',
'  l_result apex_plugin.t_page_item_render_result; -- Result object to be returned',
'  l_page_item_name varchar2(100);  -- Item name (different than ID)',
'  l_html varchar2(4000); -- Used for temp HTML',
'',
'  -- Application Plugin Attributes',
'  l_button_img apex_appl_plugins.attribute_01%type := p_plugin.attribute_01;',
'',
'  -- Item Plugin Attributes',
'  l_show_on apex_application_page_items.attribute_01%type := lower(p_item.attribute_01); -- When to show date picker. Options: focus, button, both',
'  l_date_picker_type apex_application_page_items.attribute_01%type := lower(p_item.attribute_02); -- from or to',
'  -- Note: If this cahnages from attribute 03 the need to modify validations below',
'  l_other_item apex_application_page_items.attribute_01%type := upper(p_item.attribute_03); -- Name of other date picker item',
'',
'',
'  -- Other variables',
'  -- Oracle date formats differen from JS date formats',
'  l_orcl_date_format_mask p_item.format_mask%type; -- Oracle date format: http://www.techonthenet.com/oracle/functions/to_date.php',
'  l_js_date_format_mask p_item.format_mask%type; -- JS date format: http://docs.jquery.com/UI/Datepicker/formatDate',
'  l_other_js_date_format_mask apex_application_page_items.format_mask%type; -- This is the other datepicker''s JS date format. Required since it may not contain the same format mask as this date picker',
'',
'',
'  l_err_msg varchar2(255);',
'',
'begin',
'  -- Debug information (if app is being run in debug mode)',
'  if apex_application.g_debug then',
'    apex_plugin_util.debug_page_item (',
'      p_plugin => p_plugin,',
'      p_page_item => p_item,',
'      p_value => p_value,',
'      p_is_readonly => p_is_readonly,',
'      p_is_printer_friendly => p_is_printer_friendly);',
'  end if;',
'',
'  -- handle read only and printer friendly',
'  if p_is_readonly or p_is_printer_friendly then',
'    -- omit hidden field if necessary',
'    apex_plugin_util.print_hidden_if_readonly (',
'      p_item_name => p_item.name,',
'      p_value => p_value,',
'      p_is_readonly => p_is_readonly,',
'      p_is_printer_friendly => p_is_printer_friendly);',
'',
'    -- omit display span with the value',
'    apex_plugin_util.print_display_only (',
'      p_item_name => p_item.name,',
'      p_display_value => p_value,',
'      p_show_line_breaks => false,',
'      p_escape => true, -- this is recommended to help prevent XSS',
'      p_attributes => p_item.element_attributes);',
'  else',
'    -- Not read only',
'    -- Get name. Used in the "name" form element attribute which is different than the "id" attribute',
'    l_page_item_name := apex_plugin.get_input_name_for_page_item (p_is_multi_value => false);',
'',
'    -- Validations (configuration)',
'    select',
'      case',
'        -- Correspending date item must be different than self (Issue $5)',
'        when pi_org.item_name = pi_other.item_name then',
'          ''%ERROR_PREFIX% "'' || pa_ci.prompt || ''" must be a different page item (can''''t be the same as self).''',
'        -- Other item should exist',
'        when pi_other.item_name is null then',
'          ''%ERROR_PREFIX% "'' || pa_ci.prompt || ''" item (%OTHER_ITEM_NAME%) does not exist''',
'        -- Check that corresponding item is also from/to date picker',
'        when pi_org.display_as_code != pi_other.display_as_code then',
'          ''%ERROR_PREFIX% %OTHER_ITEM_NAME% must be of same type ('' || pi_org.display_as || '')''',
'        -- Check that corresponding item points to this one',
'        when nvl(pi_other.attribute_03,''a'') != pi_org.item_name then',
'          ''%ERROR_PREFIX% "'' || pa_ci.prompt || ''" for %OTHER_ITEM_NAME% is not set to %ITEM_NAME%''',
'        else',
'          null',
'      end err_msg',
'    into',
'      l_err_msg',
'    from',
'      apex_application_page_items pi_org,',
'      apex_application_page_items pi_other,',
'      apex_appl_plugin_attributes pa_ci -- corresponding item attribute',
'    where 1=1',
'      and pi_org.application_id = apex_application.g_flow_id',
'      and pi_org.item_name = p_item.name',
'      and pi_org.application_id = pi_other.application_id(+)',
'      and pi_org.attribute_03 = pi_other.item_name(+)',
'      -- Attributes',
'      and pa_ci.application_id = pi_org.application_id',
'      and upper(pi_org.display_as_code) = upper(''PLUGIN_'' || pa_ci.plugin_name)',
'      and pa_ci.attribute_sequence = 3',
'    ;',
'',
'    if l_err_msg is not null then',
'      l_err_msg := replace(l_err_msg, ''%ERROR_PREFIX%'', ''%ITEM_NAME% Configuration Error:'');',
'      l_err_msg := replace(l_err_msg, ''%ITEM_NAME%'', p_item.name);',
'      l_err_msg := replace(l_err_msg, ''%OTHER_ITEM_NAME%'', l_other_item);',
'',
'      raise_application_error(-20001, l_err_msg);',
'    end if;',
'',
'',
'',
'    -- SET VALUES',
'',
'    -- If no format mask is defined use the system level date format',
'    l_orcl_date_format_mask :=',
'      nvl(',
'        apex_plugin_util.replace_substitutions(p_value => p_item.format_mask),',
'        sys_context(''userenv'',''nls_date_format''));',
'',
'    -- Convert the Oracle date format to JS format mask',
'    l_js_date_format_mask := wwv_flow_utilities.get_javascript_date_format(p_format => l_orcl_date_format_mask);',
'',
'    -- Get the corresponding date picker''s format mask',
'    select',
'      wwv_flow_utilities.get_javascript_date_format(',
'        p_format =>',
'          nvl(',
'            apex_plugin_util.replace_substitutions(p_value => max(format_mask)), sys_context(''userenv'',''nls_date_format'')))',
'    into l_other_js_date_format_mask',
'    from apex_application_page_items',
'    where application_id = l_application_id',
'      and page_id = l_page_id',
'      and item_name = upper(l_other_item);',
'',
'    -- OUTPUT',
'',
'    -- Print input element',
'    l_html := ''<input type="text" id="%ID%" name="%NAME%" value="%VALUE%" autocomplete="off" size="%SIZE%" maxlength="%MAX_LENGTH%">'';',
'    l_html := replace(l_html, ''%ID%'', p_item.name);',
'    l_html := replace(l_html, ''%NAME%'', l_page_item_name);',
'    l_html := replace(l_html, ''%VALUE%'', p_value);',
'    l_html := replace(l_html, ''%SIZE%'', p_item.element_width);',
'    l_html := replace(l_html, ''%MAX_LENGTH%'', p_item.element_max_length);',
'    sys.htp.p(l_html);',
'',
'    -- Initialize the fromToDatePicker',
'    l_html :=',
'    ''$("#%NAME%").oosFromToDatePicker({',
'      correspondingDatePicker: {',
'        %OTHER_DATE_FORMAT%',
'        %ID%',
'        %VALUE_END_ELEMENT%',
'      },',
'      datePickerAttrs: {',
'        %DATE_FORMAT%',
'        %SHOW_ON_END_ELEMENT%',
'      },',
'      %DATE_PICKER_TYPE_END_ELEMENT%',
'    });'';',
'    l_html := replace(l_html, ''%NAME%'', p_item.name);',
'    -- Issue #4: Don''t escape date formats',
'    l_html := replace(l_html, ''%OTHER_DATE_FORMAT%'', apex_javascript.add_attribute(''dateFormat'',  l_other_js_date_format_mask));',
'    l_html := replace(l_html, ''%DATE_FORMAT%'', apex_javascript.add_attribute(''dateFormat'',  l_js_date_format_mask));',
'    l_html := replace(l_html, ''%ID%'', apex_javascript.add_attribute(''id'', l_other_item));',
'    l_html := replace(l_html, ''%VALUE_END_ELEMENT%'', apex_javascript.add_attribute(''value'',  apex_escape.html(v(l_other_item)), false, false));',
'    l_html := replace(l_html, ''%SHOW_ON_END_ELEMENT%'', apex_javascript.add_attribute(''showOn'',  apex_escape.html(l_show_on), false, false));',
'    l_html := replace(l_html, ''%DATE_PICKER_TYPE_END_ELEMENT%'', apex_javascript.add_attribute(''datePickerType'',  apex_escape.html(l_date_picker_type), false, false));',
'',
'    apex_javascript.add_onload_code (p_code => l_html);',
'',
'    -- Tell apex that this field is navigable',
'    l_result.is_navigable := false;',
'',
'  end if; -- f_render_from_to_datepicker',
'',
'  return l_result;',
'end f_render_from_to_datepicker;',
'  ',
'',
'',
'function f_validate_from_to_datepicker (',
'  p_item in apex_plugin.t_page_item,',
'  p_plugin in apex_plugin.t_plugin,',
'  p_value in varchar2 )',
'  return apex_plugin.t_page_item_validation_result',
'as',
'  -- Variables',
'  l_orcl_date_format apex_application_page_items.format_mask%type; -- oracle date format',
'  l_date date;',
'',
'  -- Other attributes',
'  l_other_orcl_date_format apex_application_page_items.format_mask%type;',
'  l_other_date date;',
'  l_other_label apex_application_page_items.label%type;',
'  l_other_item_val varchar2(255);',
'',
'  -- APEX information',
'  l_application_id apex_applications.application_id%type := apex_application.g_flow_id;',
'  l_page_id apex_application_pages.page_id%type := apex_application.g_flow_step_id;',
'',
'  -- Item Plugin Attributes',
'  l_date_picker_type apex_application_page_items.attribute_01%type := lower(p_item.attribute_02); -- from/to',
'  l_other_item apex_application_page_items.attribute_01%type := upper(p_item.attribute_03); -- item name of other date picker',
'',
'  -- Return',
'  l_result apex_plugin.t_page_item_validation_result;',
'',
'begin',
'  -- Debug information (if app is being run in debug mode)',
'  if apex_application.g_debug then',
'    apex_plugin_util.debug_page_item (',
'      p_plugin => p_plugin,',
'      p_page_item => p_item,',
'      p_value => p_value,',
'      p_is_readonly => false,',
'      p_is_printer_friendly => false);',
'  end if;',
'',
'  -- If no value then nothing to validate',
'  if p_value is null then',
'    return l_result;',
'  end if;',
'',
'  -- Check that it''s a valid date',
'  select nvl(max(format_mask), sys_context(''userenv'',''nls_date_format''))',
'  into l_orcl_date_format',
'  from apex_application_page_items',
'  where item_id = p_item.id;',
'',
'  l_orcl_date_format := apex_plugin_util.replace_substitutions(p_value => l_orcl_date_format);',
'',
'  if not wwv_flow_utilities.is_date (p_date => p_value, p_format => l_orcl_date_format) then',
'    l_result.message := ''#LABEL# Invalid date'';',
'    return l_result;',
'  else',
'    l_date := to_date(p_value, l_orcl_date_format);',
'  end if;',
'',
'  -- Check that from/to date have valid date range',
'  -- Only do this for From dates',
'',
'  -- At this point the date exists and is valid.',
'  -- Only check for "from" dates so error message appears once',
'  if l_date_picker_type = ''from'' THEN',
'',
'    if length(v(l_other_item)) > 0 then',
'      select nvl(max(format_mask), sys_context(''userenv'',''nls_date_format'')), max(label)',
'      into l_other_orcl_date_format, l_other_label',
'      from apex_application_page_items',
'      where application_id = l_application_id',
'        and page_id = l_page_id',
'        and item_name = upper(l_other_item);',
'',
'      l_other_orcl_date_format := apex_plugin_util.replace_substitutions(p_value => l_other_orcl_date_format);',
'      l_other_item_val := v(l_other_item);',
'',
'      if wwv_flow_utilities.is_date (',
'        p_date => l_other_item_val,',
'        p_format => l_other_orcl_date_format) then',
'        l_other_date := to_date(l_other_item_val, l_other_orcl_date_format);',
'      end if;',
'',
'    end if;',
'',
'    -- If other date is not valid or does not exist then no stop validation.',
'    if l_other_date is null then',
'      return l_result;',
'    end if;',
'',
'    -- Can now compare min/max range.',
'    -- Remember "this" date is the from date. "other" date is the to date',
'    if l_date > l_other_date then',
'      l_result.message := ''#LABEL# must be less than or equal to '' || l_other_label;',
'      l_result.display_location := apex_plugin.c_inline_in_notifiction; -- Force to display inline only',
'      return l_result;',
'    end if;',
'',
'  end if; -- v_date_picker_type = from',
'',
'  -- No errors',
'  return l_result;',
'',
'end f_validate_from_to_datepicker;',
'',
''))
,p_render_function=>'f_render_from_to_datepicker'
,p_validation_function=>'f_validate_from_to_datepicker'
,p_standard_attributes=>'VISIBLE:SESSION_STATE:READONLY:ESCAPE_OUTPUT:SOURCE:FORMAT_MASK_DATE:ELEMENT:WIDTH:ELEMENT_OPTION:ENCRYPT'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_utilities.join(wwv_flow_t_varchar2(
'<p>',
'	<strong>ClariFit FromTo Date Picker for APEX</strong></p>',
'<div>',
'	Plug-in Type: Item</div>',
'<div>',
'	Summary: Handles automatically changing the min/max dates in date picker</div>',
'<div>',
'	&nbsp;</div>',
'<div>',
'	<em><strong>Depends:</strong></em></div>',
'<div>',
'	&nbsp;jquery.ui.datepicker.js</div>',
'<div>',
'	&nbsp;$.console.js &nbsp;- http://code.google.com/p/js-console-wrapper/</div>',
'<div>',
'	&nbsp;</div>',
'<div>',
'	Special thanks to Dan McGhan (http://www.danielmcghan.us) for his JavaScript help</div>',
'<div>',
'	&nbsp;</div>',
'<div>',
'	<em><strong>Contact information</strong></em></div>',
'<div>',
'	Developed by ClariFit Inc.</div>',
'<div>',
'	http://www.clarifit.com</div>',
'<div>',
'	apex@clarifit.com</div>',
'<div>',
'	&nbsp;</div>',
'<div>',
'	<em><strong>License</strong></em></div>',
'<div>',
'	Licensed Under: GNU General Public License, version 3 (GPL-3.0) - http://www.opensource.org/licenses/gpl-3.0.html</div>',
'<div>',
'	&nbsp;</div>',
'<div>',
'	<strong><em>About</em></strong></div>',
'<div>',
'	This plugin was highlighted in the book: Expert Oracle Application Express Plugins&nbsp;<a href="http://goo.gl/089zi">http://goo.gl/089zi</a></div>',
'<div>',
'	&nbsp;</div>',
'<div>',
'	<em><strong>Info</strong></em></div>',
'<div>',
'	To use this plugin, create an item (of type plugin) and select the ClariFit From/To Date Picker. The two main attributes are <em>Date Type</em> (whether this is a min or max date) and&nbsp;<em>Corresponding Date Item. &nbsp;</em>The corresponding da'
||'te item is the other date item that this date picker will use to manage the dynamic min/max restrictions. The corresponding date item should also be a ClariFit From/To Date Picker item.</div>'))
,p_version_identifier=>'2.1.0'
,p_about_url=>'https://github.com/OraOpenSource/apex-plugin-from-to-datepicker'
,p_plugin_comment=>'@MDSOUZA 6-MAY-2012: Remove additional commas at the end of various JSON objects that was causing an IE7 error "Expected identifier String or Number"'
,p_files_version=>7
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(23917664186031262484)
,p_plugin_id=>wwv_flow_api.id(23917661801437229060)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Show'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'both'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(23917664889494263452)
,p_plugin_attribute_id=>wwv_flow_api.id(23917664186031262484)
,p_display_sequence=>10
,p_display_value=>'On focus'
,p_return_value=>'focus'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(23917665291572264073)
,p_plugin_attribute_id=>wwv_flow_api.id(23917664186031262484)
,p_display_sequence=>20
,p_display_value=>'On icon click'
,p_return_value=>'button'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(23917665693303264555)
,p_plugin_attribute_id=>wwv_flow_api.id(23917664186031262484)
,p_display_sequence=>30
,p_display_value=>'Both'
,p_return_value=>'both'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(23917666378543269784)
,p_plugin_id=>wwv_flow_api.id(23917661801437229060)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Date Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'from'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(23917667085123271682)
,p_plugin_attribute_id=>wwv_flow_api.id(23917666378543269784)
,p_display_sequence=>10
,p_display_value=>'From Date'
,p_return_value=>'from'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(23917667488240272538)
,p_plugin_attribute_id=>wwv_flow_api.id(23917666378543269784)
,p_display_sequence=>20
,p_display_value=>'To Date'
,p_return_value=>'to'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(23917668202784276717)
,p_plugin_id=>wwv_flow_api.id(23917661801437229060)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Corresponding Date Item'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>true
,p_is_translatable=>false
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A2A0A202A204F72614F70656E536F757263652046726F6D546F2044617465205069636B657220666F7220415045580A202A20506C75672D696E20547970653A204974656D0A202A2053756D6D6172793A2048616E646C6573206175746F6D61746963';
wwv_flow_api.g_varchar2_table(2) := '616C6C79206368616E67696E6720746865206D696E2F6D61782064617465730A202A0A202A20446570656E64733A0A202A20206A71756572792E75692E646174657069636B65722E6A730A202A0A202A205370656369616C207468616E6B7320746F2044';
wwv_flow_api.g_varchar2_table(3) := '616E204D634768616E2028687474703A2F2F7777772E64616E69656C6D636768616E2E75732920666F7220686973204A6176615363726970742068656C700A202A0A202A2056657273696F6E3A0A202A2020312E302E313A204669786564204945203720';
wwv_flow_api.g_varchar2_table(4) := '69737375652077686963682068616420657874726120636F6D6D61206166746572207365766572616C204A534F4E206F626A656374732063617573696E67206120224578706563746564206964656E74696669657220537472696E67206F72204E756D62';
wwv_flow_api.g_varchar2_table(5) := '657222206572726F72206D6573736167650A202A2020312E302E303A20496E697469616C0A202A2020322E302E303A204D6967726174652066726F6D20436C61726946697420706C7567696E20746F204F72614F70656E536F7572636520616E64206275';
wwv_flow_api.g_varchar2_table(6) := '696C7420696E204150455820352E300A202A0A202A205E5E5E20436F6E7461637420696E666F726D6174696F6E205E5E5E0A202A20446576656C6F706564206279204F72614F70656E536F757263650A202A20687474703A2F2F7777772E6F72616F7065';
wwv_flow_api.g_varchar2_table(7) := '6E736F757263652E636F6D0A202A206D617274696E40636C6172696669742E636F6D0A202A0A202A205E5E5E204C6963656E7365205E5E5E0A202A204C6963656E73656420556E6465723A20546865204D4954204C6963656E736520284D495429202D20';
wwv_flow_api.g_varchar2_table(8) := '687474703A2F2F7777772E6F70656E736F757263652E6F72672F6C6963656E7365732F67706C2D332E302E68746D6C0A202A0A202A2040617574686F72204D617274696E204769666679204427536F757A61202D20687474703A2F2F7777772E74616C6B';
wwv_flow_api.g_varchar2_table(9) := '617065782E636F6D0A202A2F0A2866756E6374696F6E28242C20776964676574297B0A2020242E776964676574282775692E6F6F7346726F6D546F446174655069636B6572272C207B0A202020202F2F2064656661756C74206F7074696F6E730A202020';
wwv_flow_api.g_varchar2_table(10) := '206F7074696F6E733A207B0A2020202020202F2F496E666F726D6174696F6E2061626F757420746865206F746865722064617465207069636B65720A202020202020636F72726573706F6E64696E67446174655069636B65723A207B0A20202020202020';
wwv_flow_api.g_varchar2_table(11) := '2064617465466F726D61743A2027272C20202F2F4E656564206F74686572206461746520666F726D61742073696E6365206974206D6179206E6F74206265207468652073616D652061732063757272656E74206461746520666F726D61740A2020202020';
wwv_flow_api.g_varchar2_table(12) := '20202069643A2027272C0A202020202020202076616C75653A2027270A20202020202020207D2C202F2F56616C756520647572696E672070616765206C6F61640A2020202020202F2F4F7074696F6E7320666F7220746869732064617465207069636B65';
wwv_flow_api.g_varchar2_table(13) := '720A202020202020646174655069636B657241747472733A207B0A20202020202020206175746F53697A653A2066616C73652C202F2F204675747572653A207365652069737375652023310A2020202020202020627574746F6E546578743A20273C7370';
wwv_flow_api.g_varchar2_table(14) := '616E20636C6173733D22612D49636F6E2069636F6E2D63616C656E646172223E3C2F7370616E3E3C7370616E20636C6173733D22752D56697375616C6C7948696464656E223E506F7075702043616C656E6461723A20537562736372697074696F6E7320';
wwv_flow_api.g_varchar2_table(15) := '696E206566666563742046726F6D3C7370616E3E3C2F7370616E3E3C2F7370616E3E272C0A20202020202020206368616E67654D6F6E74683A2066616C73652C0A20202020202020206368616E6765596561723A2066616C73652C0A2020202020202020';
wwv_flow_api.g_varchar2_table(16) := '64617465466F726D61743A20276D6D2F64642F7979272C202F2F44656661756C74206461746520666F726D61742E2057696C6C2062652073657420627920706C7567696E0A202020202020202073686F77416E696D3A2027272C202F2F42792064656661';
wwv_flow_api.g_varchar2_table(17) := '756C742064697361626C6520616E696D6174696F6E0A202020202020202073686F774F6E3A2027626F7468277D2C0A202020202020646174655069636B6572547970653A2027272C202F2F66726F6D206F7220746F0A202020202020627574746F6E436C';
wwv_flow_api.g_varchar2_table(18) := '61737365733A2027612D427574746F6E20612D427574746F6E2D2D63616C656E64617227202F2F43535320436C617373657320746F2061646420746F20627574746F6E730A202020207D2C0A0A202020202F2A2A0A20202020202A20496E69742066756E';
wwv_flow_api.g_varchar2_table(19) := '6374696F6E2E20546869732066756E6374696F6E2077696C6C2062652063616C6C656420656163682074696D652074686520776964676574206973207265666572656E6365642077697468206E6F20706172616D65746572730A20202020202A2F0A2020';
wwv_flow_api.g_varchar2_table(20) := '20205F696E69743A2066756E6374696F6E28297B0A20202020202076617220756977203D20746869733B0A0A2020202020202F2F466F72207468697320706C75672D696E2074686572652773206E6F20636F646520726571756972656420666F72207468';
wwv_flow_api.g_varchar2_table(21) := '69732073656374696F6E0A2020202020202F2F4C656674206865726520666F722064656D6F6E7374726174696F6E20707572706F7365730A202020202020617065782E64656275672E6C6F67287569772E5F73636F70652C20275F696E6974272C207569';
wwv_flow_api.g_varchar2_table(22) := '77293B0A202020207D2C202F2F5F696E69740A0A202020202F2A2A0A20202020202A205365742070726976617465207769646765742076617261626C65730A20202020202A2F0A202020205F736574576964676574566172733A2066756E6374696F6E28';
wwv_flow_api.g_varchar2_table(23) := '297B0A20202020202076617220756977203D20746869733B0A0A2020202020207569772E5F73636F7065203D202775692E6F6F7346726F6D546F446174655069636B6572273B202F2F466F7220646562756767696E670A0A2020202020207569772E5F76';
wwv_flow_api.g_varchar2_table(24) := '616C756573203D207B0A202020202020202073686F7274596561724375746F66663A203330202F2F726F6C6C206F76657220796561720A2020202020207D3B0A0A2020202020207569772E5F656C656D656E7473203D207B0A2020202020202020246F74';
wwv_flow_api.g_varchar2_table(25) := '686572446174653A206E756C6C2C0A202020202020202024656C656D656E744F626A3A2024287569772E656C656D656E74290A2020202020207D3B0A0A202020207D2C202F2F5F736574576964676574566172730A0A202020202F2A2A0A20202020202A';
wwv_flow_api.g_varchar2_table(26) := '204372656174652066756E6374696F6E3A2043616C6C6564207468652066697273742074696D6520776964676574206973206173736F63696174656420746F20746865206F626A6563740A20202020202A20446F657320616C6C20746865207265717569';
wwv_flow_api.g_varchar2_table(27) := '7265642073657475702065746320616E642062696E6473206368616E6765206576656E740A20202020202A2F0A202020205F6372656174653A2066756E6374696F6E28297B0A20202020202076617220756977203D20746869733B0A0A20202020202075';
wwv_flow_api.g_varchar2_table(28) := '69772E5F7365745769646765745661727328293B0A0A20202020202076617220636F6E736F6C6547726F75704E616D65203D207569772E5F73636F7065202B20275F637265617465273B0A2020202020202F2F20617065782E64656275672E67726F7570';
wwv_flow_api.g_varchar2_table(29) := '436F6C6C617073656428636F6E736F6C6547726F75704E616D65293B0A202020202020617065782E64656275672E6C6F672827746869733A272C20756977293B0A202020202020617065782E64656275672E6C6F672827656C656D656E743A272C207569';
wwv_flow_api.g_varchar2_table(30) := '772E656C656D656E745B305D293B0A0A2020202020207661720A20202020202020206F74686572446174652C0A20202020202020206D696E44617465203D2027272C0A20202020202020206D617844617465203D2027270A2020202020203B0A0A202020';
wwv_flow_api.g_varchar2_table(31) := '2020202F2F4765742074686520696E697469616C206D696E2F6D6178206461746573207265737472696374696F6E730A2020202020202F2F4966206F746865722064617465206973206E6F742077656C6C20666F726D6D6174656420616E206578636570';
wwv_flow_api.g_varchar2_table(32) := '74696F6E2077696C6C2062652072616973650A2020202020207472797B0A20202020202020206F7468657244617465203D207569772E6F7074696F6E732E636F72726573706F6E64696E67446174655069636B65722E76616C756520213D202727203F20';
wwv_flow_api.g_varchar2_table(33) := '242E646174657069636B65722E706172736544617465287569772E6F7074696F6E732E636F72726573706F6E64696E67446174655069636B65722E64617465466F726D61742C207569772E6F7074696F6E732E636F72726573706F6E64696E6744617465';
wwv_flow_api.g_varchar2_table(34) := '5069636B65722E76616C75652C207B73686F7274596561724375746F66663A207569772E5F76616C7565732E73686F7274596561724375746F66667D29203A2027270A20202020202020206D696E44617465203D207569772E6F7074696F6E732E646174';
wwv_flow_api.g_varchar2_table(35) := '655069636B65725479706520203D3D2027746F27203F206F7468657244617465203A2027272C0A20202020202020206D617844617465203D207569772E6F7074696F6E732E646174655069636B657254797065203D3D202766726F6D27203F206F746865';
wwv_flow_api.g_varchar2_table(36) := '7244617465203A2027270A20202020202020207569772E5F656C656D656E74732E246F7468657244617465203D202428272327202B207569772E6F7074696F6E732E636F72726573706F6E64696E67446174655069636B65722E6964293B0A2020202020';
wwv_flow_api.g_varchar2_table(37) := '207D0A20202020202063617463682028657272297B0A2020202020202020617065782E64656275672E7761726E2827496E76616C6964204F746865722044617465272C20756977293B0A2020202020207D0A0A2020202020202F2F526567697374657220';
wwv_flow_api.g_varchar2_table(38) := '446174655069636B65720A2020202020207569772E5F656C656D656E74732E24656C656D656E744F626A2E646174657069636B6572287B0A20202020202020206175746F53697A653A207569772E6F7074696F6E732E646174655069636B657241747472';
wwv_flow_api.g_varchar2_table(39) := '732E6175746F53697A652C0A2020202020202020627574746F6E546578743A207569772E6F7074696F6E732E646174655069636B657241747472732E627574746F6E546578742C0A20202020202020206368616E67654D6F6E74683A207569772E6F7074';
wwv_flow_api.g_varchar2_table(40) := '696F6E732E646174655069636B657241747472732E6368616E67654D6F6E74682C0A20202020202020206368616E6765596561723A207569772E6F7074696F6E732E646174655069636B657241747472732E6368616E6765596561722C0A202020202020';
wwv_flow_api.g_varchar2_table(41) := '202064617465466F726D61743A207569772E6F7074696F6E732E646174655069636B657241747472732E64617465466F726D61742C0A20202020202020206D696E446174653A206D696E446174652C0A20202020202020206D6178446174653A206D6178';
wwv_flow_api.g_varchar2_table(42) := '446174652C0A202020202020202073686F77416E696D3A207569772E6F7074696F6E732E646174655069636B657241747472732E73686F77416E696D2C0A202020202020202073686F774F6E3A207569772E6F7074696F6E732E646174655069636B6572';
wwv_flow_api.g_varchar2_table(43) := '41747472732E73686F774F6E2C0A20202020202020202F2F4576656E74730A20202020202020206F6E53656C6563743A2066756E6374696F6E2864617465546578742C20696E7374297B0A202020202020202020207661720A2020202020202020202020';
wwv_flow_api.g_varchar2_table(44) := '206578747261506172616D73203D207B2064617465546578743A2064617465546578742C20696E73743A20696E7374207D0A202020202020202020203B0A202020202020202020207569772E5F656C656D656E74732E24656C656D656E744F626A2E7472';
wwv_flow_api.g_varchar2_table(45) := '696767657228276368616E676527293B202F2F204E65656420746F2074726967676572206368616E6765206576656E7420736F2074686174206F74686572206461746520697320757064617465640A202020202020202020202F2F2023320A2020202020';
wwv_flow_api.g_varchar2_table(46) := '20202020202F2F207569772E5F656C656D656E74732E24656C656D656E744F626A2E7472696767657228276F6F7366726F6D746F646174657069636B65726F6E6368616E6765272C206578747261506172616D73293B202F2F205472696767657220506C';
wwv_flow_api.g_varchar2_table(47) := '7567696E204576656E743A20706C7567696E4576656E744F6E53656C65637420696620736F6D657468696E67206973206C697374656E696E6720746F2069740A20202020202020207D0A2020202020207D293B0A0A2020202020207569772E5F656C656D';
wwv_flow_api.g_varchar2_table(48) := '656E74732E24656C656D656E744F626A2E6F6E28276368616E67652E27202B207569772E7769646765744576656E745072656669782C2066756E6374696F6E28297B0A20202020202020202F2F205365747320746865206D696E2F6D6178206461746520';
wwv_flow_api.g_varchar2_table(49) := '666F722072656C61746564206461746520656C656D656E740A20202020202020202F2F2053696E636520746869732066756E6374696F6E206973206265696E672063616C6C656420617320616E206576656E74202274686973222072656665727320746F';
wwv_flow_api.g_varchar2_table(50) := '2074686520444F4D206F626A65637420616E64206E6F74207468652077696467657420227468697322206F626A6563740A20202020202020202F2F20756977207265666572656E6365732074686520554920576964676574202274686973220A20202020';
wwv_flow_api.g_varchar2_table(51) := '20202020617065782E64656275672E6C6F67287569772E5F73636F70652C20276F6E6368616E6765272C2074686973293B0A0A20202020202020207661720A202020202020202020206F7074696F6E546F4368616E6765203D207569772E6F7074696F6E';
wwv_flow_api.g_varchar2_table(52) := '732E646174655069636B657254797065203D3D202766726F6D27203F20276D696E4461746527203A20276D617844617465272C0A2020202020202020202073656C66446174650A20202020202020203B0A0A2020202020202020747279207B0A20202020';
wwv_flow_api.g_varchar2_table(53) := '20202020202073656C6644617465203D20242E646174657069636B65722E706172736544617465280A2020202020202020202020207569772E6F7074696F6E732E646174655069636B657241747472732E64617465466F726D61742C0A20202020202020';
wwv_flow_api.g_varchar2_table(54) := '20202020207569772E5F656C656D656E74732E24656C656D656E744F626A2E76616C28292C0A2020202020202020202020207B73686F7274596561724375746F66663A2033307D293B0A0A202020202020202020207569772E5F656C656D656E74732E24';
wwv_flow_api.g_varchar2_table(55) := '6F74686572446174652E646174657069636B657228276F7074696F6E272C206F7074696F6E546F4368616E67652C73656C6644617465293B202F2F53657420746865206D696E2F6D6178206461746520696E666F726D6174696F6E20666F722072656C61';
wwv_flow_api.g_varchar2_table(56) := '7465642064617465206F7074696F6E0A0A202020202020202020202F2F4E65656420746F2072652D6164642074686520627574746F6E20636C61737365730A202020202020202020207569772E5F656C656D656E74732E246F74686572446174652E6E65';
wwv_flow_api.g_varchar2_table(57) := '78742827627574746F6E27292E616464436C617373287569772E6F7074696F6E732E627574746F6E436C6173736573293B0A20202020202020207D20636174636820286529207B0A202020202020202020202F2F204675747572653A20416464206F7074';
wwv_flow_api.g_varchar2_table(58) := '696F6E616C20616C657274206D657373616765202863757272656E746C79204150455820646F65736E2774206F666665722074686973206E6F7220646F65732069742073757070726573732061206368616E6765206576656E74290A2020202020202020';
wwv_flow_api.g_varchar2_table(59) := '2020617065782E64656275672E6572726F722865293B0A20202020202020207D0A0A2020202020207D293B202F2F6F6E0A0A2020202020202F2F204F6E6C792061646420627574746F6E20636C61737320696620627574746F6E20697320746F2073686F';
wwv_flow_api.g_varchar2_table(60) := '772075700A202020202020696620287569772E6F7074696F6E732E646174655069636B657241747472732E73686F774F6E203D3D3D2027626F746827207C7C207569772E6F7074696F6E732E646174655069636B657241747472732E73686F774F6E203D';
wwv_flow_api.g_varchar2_table(61) := '3D3D2027627574746F6E2729207B0A20202020202020207569772E5F656C656D656E74732E24656C656D656E744F626A2E6E6578742827627574746F6E27292E616464436C617373287569772E6F7074696F6E732E627574746F6E436C6173736573293B';
wwv_flow_api.g_varchar2_table(62) := '0A2020202020207D0A0A2020202020202F2F20526567697374657220617065782E6974656D2063616C6C6261636B730A2020202020202F2F204578616D706C657320636F706965642066726F6D207769646765742E646174657069636B65722E6A730A20';
wwv_flow_api.g_varchar2_table(63) := '20202020207769646765742E696E6974506167654974656D287569772E656C656D656E745B305D2E69642C207B0A2020202020202020656E61626C65203A2066756E6374696F6E2829207B0A202020202020202020207569772E5F656C656D656E74732E';
wwv_flow_api.g_varchar2_table(64) := '24656C656D656E744F626A0A2020202020202020202020202E646174657069636B65722827656E61626C652729202F2F2063616C6C206E6174697665206A517565727920554920656E61626C650A2020202020202020202020202E72656D6F7665436C61';
wwv_flow_api.g_varchar2_table(65) := '73732827617065785F64697361626C656427293B202F2F2072656D6F76652064697361626C656420636C6173730A20202020202020207D2C0A202020202020202064697361626C65203A2066756E6374696F6E2829207B0A202020202020202020207569';
wwv_flow_api.g_varchar2_table(66) := '772E5F656C656D656E74732E24656C656D656E744F626A0A2020202020202020202020202E646174657069636B6572282764697361626C652729202F2F2063616C6C206E6174697665206A51756572792055492064697361626C650A2020202020202020';
wwv_flow_api.g_varchar2_table(67) := '202020202E616464436C6173732827617065785F64697361626C656427293B202F2F206164642064697361626C656420636C61737320746F20656E737572652076616C7565206973206E6F7420504F535465640A20202020202020207D0A202020202020';
wwv_flow_api.g_varchar2_table(68) := '7D293B0A0A2020202020202F2F20617065782E64656275672E67726F7570456E6428636F6E736F6C6547726F75704E616D65293B0A202020207D2C2F2F5F6372656174650A0A202020202F2A2A0A20202020202A2052656D6F76657320616C6C2066756E';
wwv_flow_api.g_varchar2_table(69) := '6374696F6E616C697479206173736F636961746564207769746820746865206F6F7346726F6D546F446174655069636B65720A20202020202A2057696C6C2072656D6F766520746865206368616E6765206576656E742061732077656C6C0A2020202020';
wwv_flow_api.g_varchar2_table(70) := '2A204F6464732061726520746869732077696C6C206E6F742062652063616C6C65642066726F6D20415045582E0A20202020202A2F0A2020202064657374726F793A2066756E6374696F6E2829207B0A20202020202076617220756977203D2074686973';
wwv_flow_api.g_varchar2_table(71) := '3B0A0A202020202020617065782E64656275672E6C6F67287569772E5F73636F70652C202764657374726F79272C20756977293B0A202020202020242E5769646765742E70726F746F747970652E64657374726F792E6170706C79287569772C20617267';
wwv_flow_api.g_varchar2_table(72) := '756D656E7473293B202F2F2064656661756C742064657374726F790A2020202020202F2F20756E726567697374657220646174657069636B65720A20202020202024287569772E656C656D656E74292E646174657069636B6572282764657374726F7927';
wwv_flow_api.g_varchar2_table(73) := '293B0A202020207D2F2F64657374726F790A20207D293B202F2F75692E6F6F7346726F6D546F446174655069636B65720A0A7D2928617065782E6A51756572792C20617065782E776964676574293B0A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(64493997484646852)
,p_plugin_id=>wwv_flow_api.id(23917661801437229060)
,p_file_name=>'js/jquery.ui.oosFromToDatePicker.js'
,p_mime_type=>'application/x-javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false), p_is_component_import => true);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
