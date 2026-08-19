/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDValidatedReportsController.
* @Why   : Retrieves Validated Reports metadata needed to build "Validated Reports" visualforce page and executes chosen Validated Report
*          with filters configuration entered by User on "Validated Reports" page.
* @When  : 23-MAR-2017.
* @Where : From ADDValidatedReportsController class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer          Date                 Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin	    		 23-MAR-2017		  Work ID / Case ID       Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc              24-APR-2020          DEF #79 fix             Apply cross filtering in VR reports when some of the Product-Ticket fields
*                                                                 (Product List/Part Number, Likely Cause,  Batch/Lot/Serial#, Product Family)
*                                                                 or combination of them is selected as filter criteria.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob              15-JUN-2020          Code Audit              Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih              19-JUN-2020          DEF #98 fix             Changed Validated Reports names.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak              02-JUL-2020          Code Audit              Added header class description and methods comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih              06-AUG-2020          #201.1/CHARM-3038       Added text as picklist config for Record Type names of EMDR object in the
*                                                                 FillUpTextAsPicklistConfigs method. Changed 'CMPL123CME__G7_Type_of_Report_MultiSelect__c'
*                                                                 field of EMDR object was replaced by 'DeveloperName' field of Record Type object.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih              06-AUG-2020          Code Audit              Updated class header.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih              18-AUG-2020          Code Audit              Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc              08-OCT-2020          #03/CHARM-3221          Added Delete Flag to cross-filtering. Adjusted cross-filtering logic.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob              15-OCT-2020          #03/CHARM-3221          Added logic to hide filters on demand.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob              15-OCT-2020          #53/CHARM-3316          Added logic to set 'Customer Reply Required' filter of  
*                                                                 'VR_Service / Inquiry Details (DIV08431)' report as 'Select Any' by default.
* --------------------------------------------------------------------------------------------------------------------------------------
* Lakshman           14-JUN-2021          MIR Project             Added MIR Submission Logic
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar       15-JUL-2024          CHaRM-R5                Added new cross-filter fields "Product_Family_Formula__c" and "Legal_Manufacturer_Formula__c"
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDValidatedReportsController {
    @TestVisible
    private List<String> PaCReportsIds { get; set; } //PaC ref. to Point-and-Click
    @TestVisible
    private List<String> VFReportsAPINames { get; set; } //VF ref. to VisualForce
    @TestVisible
    private List<String> TextAsPicklistConfigsNames { get; set; }
    @TestVisible
    private List<String> UnchangeableFieldsConfigsNames { get; set; }
    @TestVisible
    private List<String> ErasableByDefaultFieldsConfigsNames { get; set; }
    @TestVisible
    private List<String> FieldsWithCustomLabelsFieldsConfigsNames { get; set; }
    @TestVisible
    private List<String> FieldsWithCustomLabelsFieldsConfigsMIRNames { get; set; }
    @TestVisible
    private List<VFReportConfig> VFReportsConfigs { get; set; }
    @TestVisible
    private List<TextAsPicklistConfig> TextAsPicklistConfigs { get; set; }
    @TestVisible
    private List<FieldConfig> UnchangeableFieldsConfigs { get; set; }
    @TestVisible
    private List<FieldConfig> ErasableByDefaultFieldsConfigs { get; set; }
    @TestVisible
    private List<String> ApexClassesNamespacePrefixes { get; set; }
    @TestVisible
    private List<FieldConfig> FieldsWithCustomLabelsFieldsConfigs { get; set; }
    @TestVisible
    private List<FieldConfig> FieldsWithCustomLabelsFieldsConfigsMIR { get; set; }
    @TestVisible
    private List<FieldConfig> FieldExtraFilterValuesConfigs { get; set; }
    @TestVisible
    private List<String> FieldExtraFilterValuesConfigsNames { get; set; }
    @TestVisible
    private List<FieldConfig> HidenFieldConfigs { get; set; }
    @TestVisible
    private List<String> HidenFieldConfigsNames { get; set; }

    /**
    * key   - object API name
    * value - fields used in cross filters
    */
    // Def #03/CHARM-3221: added Delete_Flag__c as a cross-filter field
    private static final Map<String, List<String>> CROSS_OBJ_API_TO_FIELDS_CONFIG = new Map<String, List<String>>{
         'Product_Ticket__c' => new List<String>{'Likely_Cause__c', 'Product_List_Number__c',
         'Batch_Lot_Serial__c', 'Product_Family_Static__c', 'Delete_Flag__c', 'Product_Family_Formula__c', 'Legal_Manufacturer_Formula__c'} //CHaRM R5-Added new cross-filter fields "Product_Family_Formula__c" and "Legal_Manufacturer_Formula__c" by Dinesh Kumar
    };

    /**
    * key   - object API name
    * value - API name of the lookup to parent
    */
    private static final Map<String, String> CROSS_OBJ_API_TO_JOIN_FIELD_CONFIG = new Map<String, String>{
        'Product_Ticket__c' => 'Event_Ticket__c'
    };

    /**
    * key   - report name
    * value - object API to fields Map
    */
    private static final Map<String, Map<String, List<String>>> CROSS_FILTER_REGISTER = new Map<String, Map<String, List<String>>>{
            'VR_Complaint Cycle Time (see DIV08431)' => CROSS_OBJ_API_TO_FIELDS_CONFIG,
            'VR_TPM Responsible (see DIV08431)' => CROSS_OBJ_API_TO_FIELDS_CONFIG,
            'VR_Not Reportables (see DIV08431)' => CROSS_OBJ_API_TO_FIELDS_CONFIG,
            'VR_Service / Inquiry Details (DIV08431)' => CROSS_OBJ_API_TO_FIELDS_CONFIG,
            'VR_Complaint Details (see DIV08431)' => CROSS_OBJ_API_TO_FIELDS_CONFIG
    };

    public List<SelectOption> ReportSelectOptions { get; set; }
    public String SelectedReportId { get; set; }
    public String SelectedReportName { get; set; }
    public List<SelectedReportFilter> SelectedReportFilters { get; set; }

    public ADDValidatedReportsController() {
        this.SelectedReportFilters = new List<SelectedReportFilter>();
        this.FillUpPaCReportsIds();
        this.FillUpVFReportsConfigs();
        this.FillUpTextAsPicklistConfigs();
        this.FillUpUnchangeableFieldConfigs();
        this.FillUpErasableByDefaultFieldsConfigs();
        this.FillUpApexClassesNamespacePrefixes();
        this.FillUpFieldsWithCustomLabelsFieldsConfigs();
        this.FillUpFieldsWithCustomLabelsFieldsConfigsMIR();//@Lakshman
        this.FillUpFieldExtraFilterValuesConfigs();
        //Defect #3 fix BEGIN
        this.FillUpHidenFieldConfigs();
        //Defect #3 fix END
        this.GenerateReportSelectOptions();
    }

    /*
    * @Method       : FillUpPaCReportsIds.
    * @Description  : To iterate over the list of Standard Reports, to get ids of this Reports and store all the ids in the list.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpPaCReportsIds() {
        this.PaCReportsIds = new List<String>();
        for (Report validatedReport : [SELECT Id, Name FROM Report WHERE FolderName = 'Validated Report' ORDER BY Name]) {
            this.PaCReportsIds.add(validatedReport.Id);
        }
    }

    /*
    * @Method       : FillUpVFReportsConfigs.
    * @Description  : To create the list of parameters of Visualforce Reports by using VFReportConfig inner class.
    *                 The list of parameters contains Reports’ Labels, APINames and map of Filters.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpVFReportsConfigs() {
        this.VFReportsConfigs = new List<VFReportConfig>();
        Map<String, String> reportParams = new Map<String, String>();
        reportParams.put('ids', 'CMSNext Ticket Number(s)');
        this.VFReportsConfigs.add(new VFReportConfig('VR_Ticket Report', 'ComplaintReport', reportParams));
        reportParams = new Map<String, String>();
        reportParams.put('names', 'Post Market Risk Asst & Risk Ctrl ID(s)');
        this.VFReportsConfigs.add(new VFReportConfig('VR_Post Market Risk Asst & Risk Ctrl', 'RiskAsstCustomReportPage', reportParams));
        reportParams = new Map<String, String>();
        reportParams.put('names', 'Health Hazard Assessment Id(s)');
        this.VFReportsConfigs.add(new VFReportConfig('VR_Post Market Risk Evaluation: Health Hazard Assessment', 'PostMarketRiskEvalHealthHazardAssessment', reportParams));
        this.FillUpVFReportsAPINames();
    }

    /*
    * @Method       : FillUpVFReportsAPINames.
    * @Description  : To populate the list of APINames of Visualforce Reports.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpVFReportsAPINames() {
        this.VFReportsAPINames = new List<String>();
        for (VFReportConfig vfReportCfg : this.VFReportsConfigs) {
            this.VFReportsAPINames.add(vfReportCfg.APIName);
        }
    }

    /*
    * @Method       : FillUpTextAsPicklistConfigs.
    * @Description  : To create picklist values from text values of filtered Objects by using TextAsPicklistConfig inner class.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpTextAsPicklistConfigs() {
        this.TextAsPicklistConfigsNames = new List<String>();
        this.TextAsPicklistConfigs = new List<TextAsPicklistConfig>();
        TextAsPicklistConfig tapCfg = new TextAsPicklistConfig(
                'CMPL123CME__Complaint__c',
                'CMPL123CME__CMPL123_WF_Status__c',
                'SELECT CMPL123__End_Status__r.Name ' +
                        'FROM CMPL123__WF_Step__c ' +
                        'WHERE CMPL123__WF_Rule__r.CMPL123__Target_Object__c ' +
                        'LIKE \'CMPL123CME__Complaint__c%\' ' +
                        'GROUP BY CMPL123__End_Status__r.Name ' +
                        'ORDER BY CMPL123__End_Status__r.Name',
                'CMPL123__End_Status__r.Name');
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
        tapCfg = new TextAsPicklistConfig(
                'CMPL123CME__EMDR__c',
                'CMPL123CME__CMPL123_WF_Status__c',
                'SELECT CMPL123__End_Status__r.Name ' +
                        'FROM CMPL123__WF_Step__c ' +
                        'WHERE CMPL123__WF_Rule__r.CMPL123__Target_Object__c ' +
                        'LIKE \'CMPL123CME__EMDR__c%\' ' +
                        'GROUP BY CMPL123__End_Status__r.Name ' +
                        'ORDER BY CMPL123__End_Status__r.Name',
                'CMPL123__End_Status__r.Name'
        );
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
        // Fix def #201.1/CHARM-3038 start.
        tapCfg = new TextAsPicklistConfig(
                'RecordType',
                'DeveloperName',
                'SELECT DeveloperName ' +
                        'FROM RecordType ' +
                        'WHERE SobjectType=\'CMPL123CME__EMDR__c\'',
                'DeveloperName'
        );
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
        // Fix def #201.1/CHARM-3038 end.
        tapCfg = new TextAsPicklistConfig(
                'CMPL123CME__MEDDEV__c',
                'CMPL123_WF_Status__c',
                'SELECT CMPL123__End_Status__r.Name ' +
                        'FROM CMPL123__WF_Step__c ' +
                        'WHERE CMPL123__WF_Rule__r.CMPL123__Target_Object__c ' +
                        'LIKE \'CMPL123CME__MEDDEV__c%\' ' +
                        'GROUP BY CMPL123__End_Status__r.Name ' +
                        'ORDER BY CMPL123__End_Status__r.Name',
                'CMPL123__End_Status__r.Name'
        );
        //MIR Submission @Lakshman
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
        // Fix def #201.1/CHARM-3038 end.
        tapCfg = new TextAsPicklistConfig(
                'CMPL123CME__EU_MIR__c',
                'CMPL123_WF_Status__c',
                'SELECT CMPL123__End_Status__r.Name ' +
                        'FROM CMPL123__WF_Step__c ' +
                        'WHERE CMPL123__WF_Rule__r.CMPL123__Target_Object__c ' +
                        'LIKE \'CMPL123CME__EU_MIR__c%\' ' +
                        'GROUP BY CMPL123__End_Status__r.Name ' +
                        'ORDER BY CMPL123__End_Status__r.Name',
                'CMPL123__End_Status__r.Name'
        );
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
        tapCfg = new TextAsPicklistConfig(
                'Post_Market_Risk_Assessment_Risk_Contr__c',
                'CMPL123_WF_Status__c',
                'SELECT CMPL123__End_Status__r.Name ' +
                        'FROM CMPL123__WF_Step__c ' +
                        'WHERE CMPL123__WF_Rule__r.CMPL123__Target_Object__c ' +
                        'LIKE \'Post_Market_Risk_Assessment_Risk_Contr__c%\' ' +
                        'GROUP BY CMPL123__End_Status__r.Name ' +
                        'ORDER BY CMPL123__End_Status__r.Name',
                'CMPL123__End_Status__r.Name'
        );
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
        tapCfg = new TextAsPicklistConfig(
                'Translation_Task__c',
                'CMPL123_WF_Status__c',
                'SELECT CMPL123__End_Status__r.Name ' +
                        'FROM CMPL123__WF_Step__c ' +
                        'WHERE CMPL123__WF_Rule__r.CMPL123__Target_Object__c ' +
                        'LIKE \'CMPL123_WF_Status__c%\' ' +
                        'GROUP BY CMPL123__End_Status__r.Name ' +
                        'ORDER BY CMPL123__End_Status__r.Name',
                'CMPL123__End_Status__r.Name'
        );
        TextAsPicklistConfigs.add(tapCfg);
        TextAsPicklistConfigsNames.add(tapCfg.FilterObjectAPIName + tapCfg.FilterObjectFieldAPIName);
    }

    /*
    * @Method       : FillUpUnchangeableFieldConfigs.
    * @Description  : To create a list of configuration for unchangeable fields by using FieldConfig inner class.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpUnchangeableFieldConfigs() {
        this.UnchangeableFieldsConfigs = new List<FieldConfig>();
        FieldConfig uFC = new FieldConfig('VR_Not Reportables (see DIV08431)', 'CMPL123CME__Complaint__c', 'Overall_Reportable_Status__c');
        this.UnchangeableFieldsConfigs.add(uFC);
        uFC = new FieldConfig('VR_TPM Responsible (see DIV08431)', 'CMPL123CME__Complaint__c', 'Overall_Reportable_Status__c');
        this.UnchangeableFieldsConfigs.add(uFC);
        uFC = new FieldConfig('VR_eMDR Submissions (see DIV08431)', 'CMPL123CME__EMDR__c', 'CMPL123CME__CMPL123_WF_Status__c');
        this.UnchangeableFieldsConfigs.add(uFC);
        // Changed in scope of the defect #201.1/CHARM-3038:
        // 'CMPL123CME__G7_Type_of_Report_MultiSelect__c' field of EMDR object was replaced by 'DeveloperName' field of Record Type object.
        uFC = new FieldConfig('VR_eMDR Submissions (see DIV08431)', 'RecordType', 'DeveloperName');
        this.UnchangeableFieldsConfigs.add(uFC);
        uFC = new FieldConfig('VR_Translation Task (see DIV08431)', 'Translation_Task__c', 'CMPL123_WF_Status__c');
        this.UnchangeableFieldsConfigs.add(uFC);
        this.FillUpUnchangeableFieldsConfigsNames();
    }

    /*
    * @Method       : FillUpUnchangeableFieldsConfigsNames.
    * @Description  : To create a list of configurations unchangeable fields with following  parameters: Report Names, Object APINames and Field APINames.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpUnchangeableFieldsConfigsNames() {
        this.UnchangeableFieldsConfigsNames = new List<String>();
        for (FieldConfig uFC : this.UnchangeableFieldsConfigs) {
            this.UnchangeableFieldsConfigsNames.add(uFC.ReportName + uFC.ObjectAPIName + uFC.FieldAPIName);
        }
    }

    /*
    * @Method       : FillUpErasableByDefaultFieldsConfigs.
    * @Description  : To create a list of configurations for erasable by default fields.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpErasableByDefaultFieldsConfigs() {
        this.ErasableByDefaultFieldsConfigs = new List<FieldConfig>();
        FieldConfig ebdFC = new FieldConfig('VR_Complaint Cycle Time (see DIV08431)', 'CMPL123CME__Complaint__c', 'Customer_Reply_Required__c');
        this.ErasableByDefaultFieldsConfigs.add(ebdFC);
        //Defect #53/CHARM-3316 fix BEGIN
        ebdFC = new FieldConfig('VR_Service / Inquiry Details (DIV08431)', 'CMPL123CME__Complaint__c', 'Customer_Reply_Required__c');
        this.ErasableByDefaultFieldsConfigs.add(ebdFC);
        //Defect #53/CHARM-3316 fix END
        this.FillUpErasableByDefaultFieldConfigsNames();
    }

    /*
    * @Method       : FillUpErasableByDefaultFieldConfigsNames.
    * @Description  : To create a list of configurations for erasable by default fields with following parameters: Report Names, Object APINames and Field APINames.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpErasableByDefaultFieldConfigsNames() {
        this.ErasableByDefaultFieldsConfigsNames = new List<String>();
        for (FieldConfig ebdFC : this.ErasableByDefaultFieldsConfigs) {
            this.ErasableByDefaultFieldsConfigsNames.add(ebdFC.ReportName + ebdFC.ObjectAPIName + ebdFC.FieldAPIName);
        }
    }

    /*
    * @Method       : GenerateReportSelectOptions.
    * @Description  : To create a list of Select Options for Standard and Visualforce Reports.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void GenerateReportSelectOptions() {
        this.ReportSelectOptions = new List<SelectOption>();
        this.ReportSelectOptions.add(new SelectOption('Select Any', 'Select Any'));
        for (String PaCReportId : this.PaCReportsIds) {
            this.ReportSelectOptions.add(new SelectOption(PaCReportId, this.GetPaCReportDescription(PaCReportId).getReportMetadata().getName()));
        }
        for (VFReportConfig vfReportCfg : this.VFReportsConfigs) {
            this.ReportSelectOptions.add(new SelectOption(vfReportCfg.APIName, vfReportCfg.Label));
        }
    }

    /*
    * @Method       : FillUpApexClassesNamespacePrefixes.
    * @Description  : To create a list of Apex Classes namespace prefixes.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpApexClassesNamespacePrefixes() {
        this.ApexClassesNamespacePrefixes = new List<String>();
        this.ApexClassesNamespacePrefixes.add('');
        for (AggregateResult namespacePrefix : [SELECT NamespacePrefix FROM ApexClass GROUP BY NamespacePrefix]) {
            Object obj = namespacePrefix.get('NamespacePrefix');
            if (obj != null) {
                this.ApexClassesNamespacePrefixes.add(obj.toString() + '__');
            }
        }
    }

    /*
    * @Method       : FillUpFieldsWithCustomLabelsFieldsConfigs.
    * @Description  : To create the list of configurations for fields with custom labels.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpFieldsWithCustomLabelsFieldsConfigs() {
        this.FieldsWithCustomLabelsFieldsConfigs = new List<FieldConfig>();
        FieldConfig fwclfc = new FieldConfig('VR_MDI Submissions (see DIV08431)', 'CMPL123CME__Registered_Site__c', 'Name', 'Registered Site');
        this.FieldsWithCustomLabelsFieldsConfigs.add(fwclfc);
        this.FillUpFieldsWithCustomLabelsFieldsConfigsNames();
    }

    /*
    * @Method       : FillUpFieldsWithCustomLabelsFieldsConfigsNames.
    * @Description  : Creates the list of configurations for fields with custom labels with following parameters: Report Names, Object APINames and Field APINames.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpFieldsWithCustomLabelsFieldsConfigsNames() {
        this.FieldsWithCustomLabelsFieldsConfigsNames = new List<String>();
        for (FieldConfig fwclfc : this.FieldsWithCustomLabelsFieldsConfigs) {
            this.FieldsWithCustomLabelsFieldsConfigsNames.add(fwclfc.ReportName + fwclfc.ObjectAPIName + fwclfc.FieldAPIName);
        }
    }

    /*
    *MIR Submission Report @Lakshman
    * @Method       : FillUpFieldsWithCustomLabelsFieldsConfigsMIR.
    * @Description  : To create the list of configurations for fields with custom labels.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible 
    private void FillUpFieldsWithCustomLabelsFieldsConfigsMIR() {
        this.FieldsWithCustomLabelsFieldsConfigsMIR = new List<FieldConfig>();
        FieldConfig fwclfc = new FieldConfig('VR_EU MIR Submissions (see DIV08431)', 'CMPL123CME__Registered_Site__c', 'Name', 'Registered Site');
        this.FieldsWithCustomLabelsFieldsConfigsMIR.add(fwclfc);
        this.FillUpFieldsWithCustomLabelsFieldsConfigsMIRNames();
    }

    /*
    *MIR Submission Report @Lakshman
    * @Method       : FillUpFieldsWithCustomLabelsFieldsConfigsMIRNames.
    * @Description  : Creates the list of configurations for fields with custom labels with following parameters: Report Names, Object APINames and Field APINames.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpFieldsWithCustomLabelsFieldsConfigsMIRNames() {
        this.FieldsWithCustomLabelsFieldsConfigsMIRNames = new List<String>();
        for (FieldConfig fwclfc : this.FieldsWithCustomLabelsFieldsConfigsMIR) {
            this.FieldsWithCustomLabelsFieldsConfigsMIRNames.add(fwclfc.ReportName + fwclfc.ObjectAPIName + fwclfc.FieldAPIName);
        }
    }

    /*
    * @Method       : FillUpFieldExtraFilterValuesConfigs.
    * @Description  : To creates a list of field configurations with extra Select Option values by using FieldConfig inner class.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpFieldExtraFilterValuesConfigs() {
        this.FieldExtraFilterValuesConfigs = new List<FieldConfig>();
        List<SelectOption> extraOptions = new List<SelectOption> ();
        extraOptions.add(new SelectOption('', 'Blank'));
        FieldConfig fefvc = new FieldConfig('VR_Complaint Details (see DIV08431)', 'Product_Ticket__c', 'Likely_Cause__c', extraOptions);
        this.FieldExtraFilterValuesConfigs.add(fefvc);
        fefvc = new FieldConfig('VR_Complaint Cycle Time (see DIV08431)', 'Product_Ticket__c', 'Likely_Cause__c', extraOptions);
        this.FieldExtraFilterValuesConfigs.add(fefvc);
        fefvc = new FieldConfig('VR_Service / Inquiry Details (DIV08431)', 'Product_Ticket__c', 'Likely_Cause__c', extraOptions);
        this.FieldExtraFilterValuesConfigs.add(fefvc);
        fefvc = new FieldConfig('VR_TPM Responsible (see DIV08431)', 'Product_Ticket__c', 'Likely_Cause__c', extraOptions);
        this.FieldExtraFilterValuesConfigs.add(fefvc);
        fefvc = new FieldConfig('VR_Not Reportables (see DIV08431)', 'Product_Ticket__c', 'Likely_Cause__c', extraOptions);
        this.FieldExtraFilterValuesConfigs.add(fefvc);
        this.FillUpFieldExtraFilterValuesConfigsNames();
    }

    /*
    * @Method       : FillUpFieldExtraFilterValuesConfigsNames.
    * @Description  : Creates a list of configurations for fields with extra Select Option values with following parameters: Report Names, Object APINames and Field APINames.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpFieldExtraFilterValuesConfigsNames() {
        this.FieldExtraFilterValuesConfigsNames = new List<String>();
        for (FieldConfig fefvc : this.FieldExtraFilterValuesConfigs) {
            this.FieldExtraFilterValuesConfigsNames.add(fefvc.ReportName + fefvc.ObjectAPIName + fefvc.FieldAPIName);
        }
    }

    /*
    * @Method       : FillUpHidenFieldConfigs.
    * @Description  : To create a list of configuration for hiden fields by using FieldConfig inner class.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpHidenFieldConfigs () {
        this.HidenFieldConfigs = new List<FieldConfig>();
        FieldConfig hFC = new FieldConfig('VR_Complaint Cycle Time (see DIV08431)', 'Product_Ticket__c', 'Delete_Flag__c');
        this.HidenFieldConfigs.add(hFC);
        hFC = new FieldConfig('VR_Complaint Details (see DIV08431)', 'Product_Ticket__c', 'Delete_Flag__c');
        this.HidenFieldConfigs.add(hFC);
        hFC = new FieldConfig('VR_Not Reportables (see DIV08431)', 'Product_Ticket__c', 'Delete_Flag__c');
        this.HidenFieldConfigs.add(hFC);
        hFC = new FieldConfig('VR_Service / Inquiry Details (DIV08431)', 'Product_Ticket__c', 'Delete_Flag__c');
        this.HidenFieldConfigs.add(hFC);
        hFC = new FieldConfig('VR_TPM Responsible (see DIV08431)', 'Product_Ticket__c', 'Delete_Flag__c');
        this.HidenFieldConfigs.add(hFC);
        this.FillUpHidenFieldConfigsNames();
    }

    /*
    * @Method       : FillUpHidenFieldConfigsNames.
    * @Description  : To create a list of configurations hiden fields with following  parameters: Report Names, Object APINames and Field APINames.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void FillUpHidenFieldConfigsNames () {
        this.HidenFieldConfigsNames = new List<String>();
        for (FieldConfig hFC : this.HidenFieldConfigs) {
            this.HidenFieldConfigsNames.add(hFC.ReportName + hFC.ObjectAPIName + hFC.FieldAPIName);
        }
    }

    /*
    * @Method       : GetPaCReportDescription.
    * @Description  : To return Standard Report description.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : Reports.ReportDescribeResult rdr.
    * @Params       : Id reportId.
    */
    @TestVisible
    private Reports.ReportDescribeResult GetPaCReportDescription(Id reportId) {
        Reports.ReportDescribeResult rdr;
        try {
            rdr = Reports.ReportManager.describeReport(reportId);
        } catch (Exception e) {
            System.debug(e);
        }
        return rdr;
    }

    /*
    * @Method       : GenerateReportFiltersList.
    * @Description  : To generate a list of selected filters for a Report by using SelectedReportFilter inner class.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference GenerateReportFiltersList() {
        for (SelectOption opt : this.ReportSelectOptions) {
            if (opt.getValue() == this.SelectedReportId) {
                this.SelectedReportName = opt.getLabel();
                break;
            }
        }
        this.SelectedReportFilters.clear();
        List<String> apiNamesOfFiltersInList = new List<String>();
        if (this.PaCReportsIds.contains(SelectedReportId)) {
            Reports.ReportDescribeResult selectedReportDescription = GetPaCReportDescription(SelectedReportId);
            Reports.ReportMetadata selectedReportMetadata = selectedReportDescription.getReportMetadata();
            Integer i = 0;
            for (Reports.ReportFilter filter : selectedReportMetadata.getReportFilters()) {
                SelectedReportFilter newFilter = new SelectedReportFilter(
                        filter, i,
                        this.TextAsPicklistConfigsNames,
                        this.TextAsPicklistConfigs,
                        this.UnchangeableFieldsConfigsNames,
                        this.ErasableByDefaultFieldsConfigsNames,
                        this.SelectedReportName,
                        this.ApexClassesNamespacePrefixes,
                        this.FieldsWithCustomLabelsFieldsConfigsNames,
                        this.FieldsWithCustomLabelsFieldsConfigsMIRNames,//@Lakshman
                        this.FieldsWithCustomLabelsFieldsConfigs,
                        this.FieldsWithCustomLabelsFieldsConfigsMIR,//@Lakshman
                        this.FieldExtraFilterValuesConfigsNames,
                        this.FieldExtraFilterValuesConfigs,
                        isKnownCrossFilter(filter),
                        this.HidenFieldConfigsNames
                );
                if (!apiNamesOfFiltersInList.contains(newFilter.APIName)) {
                    this.SelectedReportFilters.add(newFilter);
                    apiNamesOfFiltersInList.add(newFilter.APIName);
                } else {
                    Integer indexOfPrevFilter = apiNamesOfFiltersInList.indexOf(newFilter.APIName);
                    SelectedReportFilter prevReportFilter = this.SelectedReportFilters.get(indexOfPrevFilter);
                    prevReportFilter.HelperIndex = i;
                    prevReportFilter.DateToValue = newFilter.DateValue;
                }
                i++;
            }
        } else if (this.VFReportsAPINames.contains(SelectedReportId)) {
            VFReportConfig vfReportCfg = this.VFReportsConfigs.get(this.VFReportsAPINames.indexOf(SelectedReportId));
            for (String apiName : vfReportCfg.Filters.keySet()) {
                this.SelectedReportFilters.add(new SelectedReportFilter(apiName, vfReportCfg.Filters.get(apiName)));
            }
        }
        return null;
    }

    /*
    * @Method       : isKnownCrossFilter.
    * @Description  : To return true or false if the map of registered cross filter names contains particular key value in filter name.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : Boolean.
    * @Params       : Reports.ReportFilter filter.
    */
    private Boolean isKnownCrossFilter(Reports.ReportFilter filter) {
        String column = filter.getColumn();
        Map<String, List<String>> filterNames = CROSS_FILTER_REGISTER.get(SelectedReportName);
        if (null == column || null == filterNames) {
            return false;
        }
        String objAPIName = column.substringBefore('.');
        return filterNames.containsKey(objAPIName) && filterNames.get(objAPIName).contains(column.substringAfter('.'));
    }

    /*
    * @Method       : RunReport.
    * @Description  : To set URL parameters for the Report and generate the Report.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference RunReport() {
        String url = '';
        String urlParameters = '';
        PageReference newReference;
        if (this.PaCReportsIds.contains(SelectedReportId)) {
            url += '/' + SelectedReportId;
            urlParameters = this.GenerateURLParametersForPaCReport();
        } else if (this.VFReportsAPINames.contains(SelectedReportId)) {
            url += '/apex/' + SelectedReportId;
            urlParameters = this.GenerateURLParametersForVFReport();
        }
        if (String.isNotBlank(urlParameters)) {
            url += '?' + urlParameters;
        }
        if (String.isNotBlank(url)) {
            newReference = new PageReference(url);
            newReference.setRedirect(true);
        }
        return newReference;
    }

    /*
    * @Method       : GenerateURLParametersForVFReport.
    * @Description  : To generate URL parameters for Visualforce Report.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : String urlParameters.
    * @Params       : N/A.
    */
    @TestVisible
    private String GenerateURLParametersForVFReport() {
        String urlParameters = '';
        for (SelectedReportFilter selectedReportFilterItem : SelectedReportFilters) {
            String urlParameter = selectedReportFilterItem.APIName + '=';
            if (String.isNotBlank(selectedReportFilterItem.TextValue)) {
                urlParameter += selectedReportFilterItem.TextValue;
            }
            urlParameter += '&';
            urlParameters += urlParameter;
        }
        urlParameters = urlParameters.removeEnd('&');
        return urlParameters;
    }

    /*
    * @Method       : GenerateURLParametersForCrossFiltersForPaCReport.
    * @Description  : To generate cross filters’ URL parameters for Standard Report.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : String urlParameter.
    * @Params       : Map<String, FieldDefinition> crossFiltersDefinitions, Map<String, List<SelectedReportFilter>> crossObjToFilters.
    */
    // Def #03/CHARM-3221: adjusted cross-filtering, will be set only when any of cross-filter fields will be selected
    @TestVisible
    private String GenerateURLParametersForCrossFiltersForPaCReport(Map<String, FieldDefinition> crossFiltersDefinitions,
         Map<String, List<SelectedReportFilter>> crossObjToFilters) {
        String urlParameter = '';
        String parentChildCrossObjParams = '';
        String childColumnsCrossObjParam = '';
        Boolean isChildColumnValueSet = false;
        Integer i = 0, j = 0;
        String urlCrossObjFormat = 'ptable{0}={1}&ocond{2}=w&rtable{3}={4}&rtablecol{5}={6}';
        String urlParamsFormat = '&sfpc{0}_{1}={2}&sfpn{3}_{4}={5}&sfpv{6}_{7}={8}';

        for (String objAPI : crossObjToFilters.keySet()) {
            String relatedEntityJoinField = CROSS_OBJ_API_TO_JOIN_FIELD_CONFIG.get(objAPI);
            String indexI = String.valueOf(i);
            List<String> crossObjparams = new List<String>{
                indexI, ValidatedReportsConfig__c.getInstance().Complaint_Entity_Id__c, indexI, indexI,
                crossFiltersDefinitions.get(relatedEntityJoinField).EntityDefinitionId,
                indexI, crossFiltersDefinitions.get(relatedEntityJoinField).DurableId.substringAfter('.')
            };
            parentChildCrossObjParams += String.format(urlCrossObjFormat, crossObjparams);
            for (SelectedReportFilter selectedFilter : crossObjToFilters.get(objAPI)) {
                String indexJ = String.valueOf(j);
                if (!String.isBlank(selectedFilter.Operator)) {
                    String value = getFilterValue(selectedFilter);
                    List<String> valuesParams = new List<String>{
                        indexI, indexJ, crossFiltersDefinitions.get(selectedFilter.APIName).DurableId.substringAfter('.'),
                        indexI, indexJ, selectedFilter.Operator, indexI, indexJ, value
                    };
                    childColumnsCrossObjParam += String.format(urlParamsFormat, valuesParams);
                    isChildColumnValueSet = true;
                } else {
                    urlParameter += '&pc' + selectedFilter.Index + '=0&';
                }
                j++;
            }
            i++;
        }
        if (isChildColumnValueSet) {
            urlParameter += parentChildCrossObjParams + childColumnsCrossObjParam;
        }

        return urlParameter;
    }

    /*
    * @Method       : getFieldDefinitions.
    * @Description  : To generate filed definitions for selected report filters, then return the map which contains qualified field definitions.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : Map<String, FieldDefinition> result.
    * @Params       : Map<String, List<SelectedReportFilter>> selectedCrossObjToFilters.
    */
    private Map<String, FieldDefinition> getFieldDefinitions(Map<String, List<SelectedReportFilter>> selectedCrossObjToFilters) {
        Set<String> relatedEntities = new Set<String>(selectedCrossObjToFilters.keySet());
        Set<String> relatedEntityJoinFields = new Set<String>();
        Set<String> fieldNames = new Set<String>();
        Map<String, FieldDefinition> result = new Map<String, FieldDefinition>();
        for (String objAPI : selectedCrossObjToFilters.keySet()) {
            for (SelectedReportFilter selectedFilter : selectedCrossObjToFilters.get(objAPI)) {
                String relatedEntityJoinField = CROSS_OBJ_API_TO_JOIN_FIELD_CONFIG.get(selectedFilter.ObjectAPIName);
                String fieldName = selectedFilter.APIName;
                if (relatedEntityJoinField != null) {
                    relatedEntityJoinFields.add(relatedEntityJoinField);
                }
                if (fieldName != null) {
                    fieldNames.add(selectedFilter.APIName);
                }
            }
        }

        if (relatedEntityJoinFields.size() > 0 && fieldNames.size() > 0) {
            for (FieldDefinition fd : [
                SELECT EntityDefinitionId, DurableId, DeveloperName, QualifiedApiName
                FROM FieldDefinition
                WHERE EntityDefinition.QualifiedApiName IN :relatedEntities
                AND (QualifiedApiName IN :relatedEntityJoinFields OR QualifiedApiName IN :fieldNames)
            ]) {
            result.put(fd.QualifiedApiName, fd);
            }
        }
        return result;
    }

    /*
    * @Method       : getFilterValue.
    * @Description  : To return text value of selected filter.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : String value.
    * @Params       : SelectedReportFilter selectedFilter.
    */
    private String getFilterValue(SelectedReportFilter selectedFilter) {
        String value = '';
        if (null != selectedFilter) {
            if (null != selectedFilter.MultiValue && selectedFilter.MultiValue.size() > 0) {
                for (String multiValueItem : selectedFilter.MultiValue) {
                    value += '"' + multiValueItem + '", ';
                }
                value = value.removeStart(' ,').removeEnd(', ');
            } else {
                value = selectedFilter.TextValue;
            }
        }
        return value;
    }

    /*
    * @Method       : GenerateURLParametersForPaCReport.
    * @Description  : To generate URL parameters for Standard Report.
    * @Invoke       : From ADDValidatedReportsController class.
    * @Return       : String.
    * @Params       : N/A.
    */
    @TestVisible
    private String GenerateURLParametersForPaCReport() {
        Map<String, List<SelectedReportFilter>> selectedCrossObjToFilters = new Map<String, List<SelectedReportFilter>>();
        String urlParameters = '';
        for (SelectedReportFilter selectedReportFilterItem : SelectedReportFilters) {
            if (selectedReportFilterItem.isCrossFilter && null != selectedReportFilterItem.ObjectAPIName) { // grab selected cross filters
                String objAPIName = selectedReportFilterItem.ObjectAPIName;
                if (!selectedCrossObjToFilters.containsKey(objAPIName)) {
                    selectedCrossObjToFilters.put(objAPIName, new List<SelectedReportFilter>{selectedReportFilterItem});
                } else {
                    selectedCrossObjToFilters.get(objAPIName).add(selectedReportFilterItem);
                }
            }
            String urlParameter = '';
            if (String.isNotBlank(selectedReportFilterItem.Operator)) {
                switch on selectedReportFilterItem.FieldType {
                    when 'picklist', 'multipicklist' {
                        String joinedValue = '';
                        for (String multiValueItem : selectedReportFilterItem.MultiValue) {
                            joinedValue += '"' + multiValueItem + '", ';
                        }
                        joinedValue = joinedValue.removeStart(' ,').removeEnd(', ');
                        urlParameter += 'pv' + selectedReportFilterItem.Index
                                + '=' + joinedValue
                                + '&pn' + selectedReportFilterItem.Index
                                + '=' + selectedReportFilterItem.Operator + '&';
                    }
                    when 'boolean' {
                        Integer valuesCount = selectedReportFilterItem.MultiValue.size();
                        if (valuesCount <= 0 || valuesCount >= 2) {
                            //If none or Yes AND No
                            urlParameter += 'pc' + selectedReportFilterItem.Index + '=0&';
                        } else {
                            //If Yes OR No
                            urlParameter += 'pv' + selectedReportFilterItem.Index
                                    + '=' + selectedReportFilterItem.MultiValue[0].replace('True', '1').replace('False', '0')
                                    + '&pn' + selectedReportFilterItem.Index
                                    + '=' + selectedReportFilterItem.Operator + '&';
                        }
                    }
                    when 'date', 'datetime' {
                        if (selectedReportFilterItem.Operator != 'range') {
                            urlParameter += 'pv' + selectedReportFilterItem.Index
                                    + '=' + selectedReportFilterItem.DateValue
                                    + '&pn' + selectedReportFilterItem.Index
                                    + '=' + selectedReportFilterItem.Operator + '&';
                            urlParameter += 'pc' + selectedReportFilterItem.HelperIndex + '=0&';
                        } else {
                            //From date
                            urlParameter += 'pv' + selectedReportFilterItem.Index
                                    + '=' + selectedReportFilterItem.DateFromValue
                                    + '&pn' + selectedReportFilterItem.Index
                                    + '=ge&';
                            //To date
                            urlParameter += 'pv' + selectedReportFilterItem.HelperIndex
                                    + '=' + selectedReportFilterItem.DateToValue
                                    + '&pn' + selectedReportFilterItem.HelperIndex
                                    + '=le&';
                        }
                    }
                    when else {
                        urlParameter += 'pv' + selectedReportFilterItem.Index
                                + '=' + selectedReportFilterItem.TextValue
                                + '&pn' + selectedReportFilterItem.Index
                                + '=' + selectedReportFilterItem.Operator + '&';
                    }
                }
            } else {
                if (!selectedReportFilterItem.FieldType.contains('date')) {
                    urlParameter += 'pc' + selectedReportFilterItem.Index + '=0&';
                } else {
                    urlParameter += 'pc' + selectedReportFilterItem.Index + '=0&' + 'pc' + selectedReportFilterItem.HelperIndex + '=0&';
                }
            }
            urlParameters += urlParameter;
        }

        if (selectedCrossObjToFilters.keySet().size() > 0) { // generate URL, based on selected cross filters
            Map<String, FieldDefinition> crossFiltersDefinitions = getFieldDefinitions(selectedCrossObjToFilters);
            urlParameters += GenerateURLParametersForCrossFiltersForPaCReport(crossFiltersDefinitions, selectedCrossObjToFilters);
        }
        urlParameters = urlParameters.removeEnd('&');
        return urlParameters;
    }

    @TestVisible
    private class SelectedReportFilter {

        public String Label { get; set; }
        public String APIName { get; set; }
        public String ObjectAPIName { get; set; }
        public Integer Index { get; set; }
        public String DateValue { get; set; }
        public String DateFromValue { get; set; }
        public String DateToValue { get; set; }
        public String[] MultiValue { get; set; }
        public String TextValue { get; set; }
        public Integer HelperIndex { get; set; }
        public String Operator { get; set; }
        public String FieldType { get; set; }
        public List<SelectOption> OperatorSelectOptions { get; set; }
        public List<SelectOption> ValueSelectOptions { get; set; }
        public Boolean IsUnchangeable { get; set; }
        public Boolean isCrossFilter { get; set; }
        public Boolean isHidden { get; set; }

        public SelectedReportFilter(String apiName, String label) {
            this.APIName = apiName;
            this.Label = label;
            this.TextValue = '';
            this.Operator = 'eq';
            this.FieldType = 'unknown';
            this.ValueSelectOptions = new List<SelectOption> ();
            this.IsUnchangeable = false;
            this.isHidden = false;
            this.GenerateOperatorSelectOptions();
        }

        public SelectedReportFilter(
                Reports.ReportFilter reportFilter,
                Integer filterIndex,
                List<String> textAsPicklistConfigsNames,
                List<TextAsPicklistConfig> textAsPicklistConfigs,
                List<String> unchangeableFieldConfigsNames,
                List<String> erasableByDefaultFieldConfigsNames,
                String selectedReportName,
                List<String> apexClassesNamespacePrefixes,
                List<String> fieldsWithCustomLabelsFieldsConfigsNames,
                List<String> FieldsWithCustomLabelsFieldsConfigsMIRNames,//@Lakshman
                List<FieldConfig> fieldsWithCustomLabelsFieldsConfigs,
                List<FieldConfig> FieldsWithCustomLabelsFieldsConfigsMIR,//@Lakshman
                List<String> fieldExtraFilterValuesConfigsNames,
                List<FieldConfig> fieldExtraFilterValuesConfigs,
                Boolean isKnownCrossFilter,
                List<String> hidenFieldConfigsNames
        ) {
            this(reportFilter,
                    filterIndex,
                    textAsPicklistConfigsNames,
                    textAsPicklistConfigs,
                    unchangeableFieldConfigsNames,
                    erasableByDefaultFieldConfigsNames,
                    selectedReportName,
                    apexClassesNamespacePrefixes,
                    fieldsWithCustomLabelsFieldsConfigsNames,
                    FieldsWithCustomLabelsFieldsConfigsMIRNames,//@Lakshman
                    fieldsWithCustomLabelsFieldsConfigs,
                    FieldsWithCustomLabelsFieldsConfigsMIR,//@Lakshman
                    fieldExtraFilterValuesConfigsNames,
                    fieldExtraFilterValuesConfigs,
                    hidenFieldConfigsNames);
            this.isCrossFilter = isKnownCrossFilter;
        }

        public SelectedReportFilter(
                Reports.ReportFilter reportFilter,
                Integer filterIndex,
                List<String> textAsPicklistConfigsNames,
                List<TextAsPicklistConfig> textAsPicklistConfigs,
                List<String> unchangeableFieldConfigsNames,
                List<String> erasableByDefaultFieldConfigsNames,
                String selectedReportName,
                List<String> apexClassesNamespacePrefixes,
                List<String> fieldsWithCustomLabelsFieldsConfigsNames,
                List<String> FieldsWithCustomLabelsFieldsConfigsMIRNames,//@Lakshman
                List<FieldConfig> fieldsWithCustomLabelsFieldsConfigs,
                List<FieldConfig> FieldsWithCustomLabelsFieldsConfigsMIR,//@Lakshman
                List<String> fieldExtraFilterValuesConfigsNames,
                List<FieldConfig> fieldExtraFilterValuesConfigs,
                List<String> hidenFieldConfigsNames
        ) {
            List<String> relatedObjects = reportFilter.getColumn().split('\\.');
            if (relatedObjects[0].startsWith('FK')) {
                relatedObjects[0] = relatedObjects[0].removeStart('FK_');
            }
            Integer relatedObjectsListSize = relatedObjects.size();
            Integer objectAPINameListIndex = relatedObjectsListSize - 2;
            Integer fieldAPINameListIndex = relatedObjectsListSize - 1;
            if (relatedObjectsListSize >= 2) {
                this.ObjectAPIName = relatedObjects.get(objectAPINameListIndex);
                this.APIName = relatedObjects.get(fieldAPINameListIndex);
                if (this.APIName.endsWith('__lookup')) {
                    this.APIName = this.APIName.removeEnd('__lookup');
                }
                DescribeFieldResult dfr = this.GetDescribeFieldResult(this.ObjectAPIName, this.APIName, apexClassesNamespacePrefixes);
                if (dfr != null) {
                    this.Label = dfr.getLabel();
                    this.FieldType = dfr.getType().name().toLowerCase();
                    this.FillUpValueSelectOptions(dfr);
                } else {
                    this.Label = this.APIName;
                    this.FieldType = 'unknown';
                    this.ValueSelectOptions = new List<SelectOption> ();
                }
            } else {
                //Can't get full API name for 'ACC' and other standard objects names by their shorten names
                String objectAndFieldAPINames = relatedObjects[0];
                this.APIName = objectAndFieldAPINames;
                this.Label = objectAndFieldAPINames;
                this.FieldType = 'unknown';
            }
            this.TextValue = reportFilter.getValue();
            if (String.IsNotBlank(this.TextValue)) {
                this.Operator = this.ConvertOperatorNameToAbbr(reportFilter.getOperator());
                if (this.FieldType.contains('date')) {
                    this.DateValue = this.TextValue.split('T').get(0);
                }
            } else {
                this.Operator = '';
            }
            if (this.FieldType.contains('list') || this.FieldType == 'boolean') {
                if (this.TextValue.contains(',')) {
                    this.MultiValue = this.TextValue.split('\\,');
                } else {
                    if (String.isNotBlank(this.TextValue)) {
                        this.MultiValue = new String[]{
                                this.TextValue
                        };
                    } else {
                        this.MultiValue = new String[]{
                        };
                    }
                }
            }
            this.Index = filterIndex;
            this.GenerateOperatorSelectOptions();
            this.AdjustFilter(
                    textAsPicklistConfigsNames,
                    textAsPicklistConfigs,
                    unchangeableFieldConfigsNames,
                    erasableByDefaultFieldConfigsNames,
                    selectedReportName,
                    fieldsWithCustomLabelsFieldsConfigsNames,
                    FieldsWithCustomLabelsFieldsConfigsMIRNames,//@Lakshman
                    fieldsWithCustomLabelsFieldsConfigs,
                    FieldsWithCustomLabelsFieldsConfigsMIR,//@Lakshman
                    fieldExtraFilterValuesConfigsNames,
                    fieldExtraFilterValuesConfigs,
                    hidenFieldConfigsNames
            );
        }

        @TestVisible
        private DescribeFieldResult GetDescribeFieldResult(String objAPIName, String fieldAPIName, List<String> apexClassesNamespacePrefixes) {
            DescribeFieldResult dfr;
            sObjectType objTypeDescribe;
            for (String acnp : apexClassesNamespacePrefixes) {
                objTypeDescribe = Schema.getGlobalDescribe().get(acnp + objAPIName);
                if (objTypeDescribe != null) {
                    this.ObjectAPIName = acnp + objAPIName;
                    break;
                } else {
                    System.debug('Cannot find ' + objAPIName + ' in \'' + acnp + '\' namespace');
                }
            }
            try {
                dfr = objTypeDescribe.getDescribe().fields.getMap().get(fieldAPIName).getDescribe();
                system.debug('dfr==>'+dfr);
            } catch (Exception ex) {
                System.debug('Cannot get all description for object with API Name \'' + objAPIName + '\' and field with API Name \'' + fieldAPIName + '\'');
            }
            return dfr;
        }

        @TestVisible
        private String ConvertOperatorNameToAbbr(String operatorName) {
            String abbr;
            switch on operatorName.toLowerCase() {
                when 'equals' {
                    abbr = 'eq';
                }
                when 'notequal' {
                    abbr = 'ne';
                }
                when 'lessthan' {
                    abbr = 'lt';
                }
                when 'greaterthan' {
                    abbr = 'gt';
                }
                when 'lessorequal' {
                    abbr = 'le';
                }
                when 'greaterorequal' {
                    abbr = 'ge';
                }
                when 'contains' {
                    abbr = 'co';
                }
                when 'notcontain' {
                    abbr = 'nc';
                }
                when 'startswith' {
                    abbr = 'sw';
                }
                when 'includes' {
                    abbr = 'in';
                }
                when 'excludes' {
                    abbr = 'ex';
                }
            }
            return abbr;
        }

        @TestVisible
        private void AdjustFilter(
                List<String> textAsPicklistConfigsNames,
                List<TextAsPicklistConfig> textAsPicklistConfigs,
                List<String> unchangeableFieldConfigsNames,
                List<String> erasableByDefaultFieldConfigsNames,
                String selectedReportName,
                List<String> fieldsWithCustomLabelsFieldsConfigsNames,
                List<String> FieldsWithCustomLabelsFieldsConfigsMIRNames,//@Lakshman
                List<FieldConfig> fieldsWithCustomLabelsFieldsConfigs,
                List<FieldConfig> FieldsWithCustomLabelsFieldsConfigsMIR,//@Lakshman
                List<String> fieldExtraFilterValuesConfigsNames,
                List<FieldConfig> fieldExtraFilterValuesConfigs,
                List<String> hidenFieldConfigsNames
        ) {
            if (String.isNotBlank(this.ObjectAPIName) && String.isNotBlank(this.APIName)) {
                String ofNamesConcat = this.ObjectAPIName + this.APIName;
                if (textAsPicklistConfigsNames.contains(ofNamesConcat)) {
                    this.ConvertTextFieldToPicklist(textAsPicklistConfigs);
                }
                if (String.isNotBlank(selectedReportName)) {
                    String rfoNamesConcat = selectedReportName + this.ObjectAPIName + this.APIName;
                    if (unchangeableFieldConfigsNames.contains(rfoNamesConcat)) {
                        this.ConvertFieldToUnchangeable();
                    } else {
                        this.IsUnchangeable = false;
                    }
                    if (erasableByDefaultFieldConfigsNames.contains(rfoNamesConcat)) {
                        this.EraseField();
                    }
                    if (fieldsWithCustomLabelsFieldsConfigsNames.contains(rfoNamesConcat)) {
                        this.ChangeFieldLabel(fieldsWithCustomLabelsFieldsConfigs.get(fieldsWithCustomLabelsFieldsConfigsNames.indexOf(rfoNamesConcat)));
                    }
                    //@Lakshman
                    if (FieldsWithCustomLabelsFieldsConfigsMIRNames.contains(rfoNamesConcat)) {
                        this.ChangeFieldLabel(FieldsWithCustomLabelsFieldsConfigsMIR.get(FieldsWithCustomLabelsFieldsConfigsMIRNames.indexOf(rfoNamesConcat)));
                    }
                    if (fieldExtraFilterValuesConfigsNames.contains(rfoNamesConcat)) {
                        this.AddExtraFilterValues(fieldExtraFilterValuesConfigs.get(fieldExtraFilterValuesConfigsNames.indexOf(rfoNamesConcat)));
                    }
                    if (hidenFieldConfigsNames.contains(rfoNamesConcat)) {
                        this.isHidden = true;
                    }
                }
            }
        }

        @TestVisible
        private void GenerateOperatorSelectOptions() {
            this.OperatorSelectOptions = new List<SelectOption>();
            //Default operators for all types
            if (this.FieldType != 'unknown') {
                OperatorSelectOptions.add(new SelectOption ('', 'Select Any'));
                OperatorSelectOptions.add(new SelectOption ('ne', 'Not equal to'));
            }
            OperatorSelectOptions.add(new SelectOption ('eq', 'Equals'));
            //Date/Date-time-specific operator
            if (this.FieldType.toLowerCase().contains('date')) {
                OperatorSelectOptions.add(new SelectOption ('range', 'Range'));
            }
            //Type-specific operators
            switch on this.FieldType {
                when 'date', 'double', 'percent', 'int', 'datetime', 'currency' {
                    OperatorSelectOptions.add(new SelectOption ('lt', 'Less than'));
                    OperatorSelectOptions.add(new SelectOption ('gt', 'Greater than'));
                    OperatorSelectOptions.add(new SelectOption ('le', 'Less or equal'));
                    OperatorSelectOptions.add(new SelectOption ('ge', 'Greater or equal'));
                }
                when 'string', 'picklist', 'textarea', 'url', 'phone', 'email' {
                    OperatorSelectOptions.add(new SelectOption ('lt', 'Less than'));
                    OperatorSelectOptions.add(new SelectOption ('gt', 'Greater than'));
                    OperatorSelectOptions.add(new SelectOption ('le', 'Less or equal'));
                    OperatorSelectOptions.add(new SelectOption ('ge', 'Greater or equal'));
                    OperatorSelectOptions.add(new SelectOption ('co', 'Contains'));
                    OperatorSelectOptions.add(new SelectOption ('nc', 'Does not contain'));
                    OperatorSelectOptions.add(new SelectOption ('sw', 'Starts with'));
                }
                when 'multipicklist' {
                    OperatorSelectOptions.add(new SelectOption ('in', 'Includes'));
                    OperatorSelectOptions.add(new SelectOption ('ex', 'Excludes'));
                }
                when 'id' {
                    OperatorSelectOptions.add(new SelectOption ('sw', 'Starts with'));
                }
                when 'reference', 'boolean' {
                    //Only default operators
                }
                when else {
                    System.debug('Unknown field type');
                }
            }
        }

        @TestVisible
        private void FillUpValueSelectOptions(DescribeFieldResult dfr) {
            this.ValueSelectOptions = new List<SelectOption> ();
            if (this.FieldType == 'multipicklist' || this.FieldType == 'picklist') {
                List<PicklistEntry> picklistEntries = dfr.getPicklistValues();
                for (PicklistEntry pE : picklistEntries) {
                    this.ValueSelectOptions.add(new SelectOption(pE.getValue(), pE.getLabel()));
                    System.debug(LoggingLevel.INFO, 'ADDVR Picklist Option: value=' + pE.getValue() + ', label=' + pE.getLabel());

                }
            } else if (this.FieldType == 'boolean') {
                this.ValueSelectOptions.add(new SelectOption('True', 'Yes'));
                this.ValueSelectOptions.add(new SelectOption('False', 'No'));
            }
        }

        @TestVisible
        private void ConvertTextFieldToPicklist(List<TextAsPicklistConfig> textAsPicklistConfigs) {
            TextAsPicklistConfig cfg;
            for (TextAsPicklistConfig textAsPicklistConfigItem : textAsPicklistConfigs) {
                if (textAsPicklistConfigItem.FilterObjectAPIName == this.ObjectAPIName && textAsPicklistConfigItem.FilterObjectFieldAPIName == this.APIName) {
                    cfg = textAsPicklistConfigItem;
                    break;
                }
            }
            if (cfg != null) {
                this.FieldType = 'multipicklist';
                if (this.TextValue.contains(',')) {
                    this.MultiValue = this.TextValue.split('\\,');
                } else {
                    this.MultiValue = new String[]{
                            this.TextValue
                    };
                }
                this.ValueSelectOptions = cfg.ValueSelectOptions;
            }
        }

        @TestVisible
        private void ConvertFieldToUnchangeable() {
            this.IsUnchangeable = true;
            if (this.FieldType.contains('list')) {
                List<Integer> indexesToRemove = new List<Integer>();
                Integer i = 0;
                for (SelectOption valOption : this.ValueSelectOptions) {
                    if (!this.MultiValue.contains(valOption.getValue())) {
                        indexesToRemove.add(i);
                    }
                    i++;
                }
                for (i = indexesToRemove.size() - 1; i >= 0; i--) {
                    this.ValueSelectOptions.remove(indexesToRemove[i]);
                }
            }
        }

        @TestVisible
        private void EraseField() {
            this.Operator = '';
            this.TextValue = '';
            this.MultiValue = new List<String>();
            this.DateValue = '';
            this.DateToValue = '';
            this.DateFromValue = '';
        }

        @TestVisible
        private void ChangeFieldLabel(FieldConfig fc) {
            this.Label = fc.FieldLabelToSet;
        }

        @TestVisible
        private void AddExtraFilterValues(FieldConfig fc) {
            this.ValueSelectOptions.addAll(fc.ExtraSelectOptions);
        }

    }

    @TestVisible
    private class VFReportConfig {

        public String Label { get; set; }
        public String APIName { get; set; }
        public Map<String, String> Filters { get; set; }

        public VFReportConfig(String label, String apiName, Map<String, String> filters) {
            this.Label = label;
            this.APIName = apiName;
            this.Filters = filters;
        }

    }

    @TestVisible
    private class TextAsPicklistConfig {
        public String FilterObjectAPIName { get; private set; }
        public String FilterObjectFieldAPIName { get; private set; }
        public String DBQueryString { get; private set; }
        public String DBQueryTargetFieldAPIName { get; private set; }
        public List<SelectOption> ValueSelectOptions { get; private set; }

        public TextAsPicklistConfig(String filterObjectAPIName, String filterObjectFieldAPIName, String DBQueryString, String dbQueryTargetFieldAPIName) {
            this.FilterObjectAPIName = filterObjectAPIName;
            this.FilterObjectFieldAPIName = filterObjectFieldAPIName;
            this.DBQueryString = DBQueryString;
            this.DBQueryTargetFieldAPIName = dbQueryTargetFieldAPIName;
            this.ValueSelectOptions = new List<SelectOption> ();
            this.FillUpValueSelectOptions();
        }

        @TestVisible
        private void FillUpValueSelectOptions() {
            List<sObject> dbQueryResult = Database.query(this.DBQueryString);
            if (this.DBQueryTargetFieldAPIName.contains('__r')) {
                this.DBQueryTargetFieldAPIName = this.DBQueryTargetFieldAPIName.right(this.DBQueryTargetFieldAPIName.length() - this.DBQueryTargetFieldAPIName.lastIndexOf('__r') - 4);
            }
            for (sObject dbQueryResultItem : dbQueryResult) {
                String dbQueryResultItemValue = dbQueryResultItem.get(this.DBQueryTargetFieldAPIName).toString();
                this.ValueSelectOptions.add(new SelectOption(dbQueryResultItemValue, dbQueryResultItemValue));
            }
        }
    }

    @TestVisible
    private class FieldConfig {
        public String ReportName { get; private set; }
        public String ObjectAPIName { get; private set; }
        public String FieldAPIName { get; private set; }
        public String FieldLabelToSet { get; private set; }
        public List<SelectOption> ExtraSelectOptions { get; private set; }

        public FieldConfig(String rprtName, String objAPIName, String fldAPIName, String fldLblToSet, List<SelectOption> extraOptions) {
            this.ReportName = rprtName;
            this.ObjectAPIName = objAPIName;
            this.FieldAPIName = fldAPIName;
            this.FieldLabelToSet = fldLblToSet;
            this.ExtraSelectOptions = extraOptions;
        }

        public FieldConfig(String rprtName, String objAPIName, String fldAPIName, List<SelectOption> extraOptions) {
            this(rprtName, objAPIName, fldAPIName, null, extraOptions);
        }

        public FieldConfig(String rprtName, String objAPIName, String fldAPIName, String fldLblToSet) {
            this(rprtName, objAPIName, fldAPIName, fldLblToSet, null);
        }

        public FieldConfig(String rprtName, String objAPIName, String fldAPIName) {
            this(rprtName, objAPIName, fldAPIName, null, null);
        }

    }
}