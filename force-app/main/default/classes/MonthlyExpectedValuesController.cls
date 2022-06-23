public with sharing class MonthlyExpectedValuesController {
    private static boolean isPermittedProfile{get;set;}
    private static Decimal totalVolume{get;set;}
    private static  Decimal totalGM{get;set;}
    private static  Decimal totalPM{get;set;}
    private static  Decimal totalVolumeFY1{get;set;}
    private static  Decimal totalGMFY1{get;set;}
    private static  Decimal totalPMFY1{get;set;}
    private static  Decimal totalVolumeFY2{get;set;}
    private static  Decimal totalGMFY2{get;set;}
    private static Decimal totalPMFY2{get;set;}
    private static String totalFY1Name{get;set;}
    private static String totalFY2Name{get;set;}
    private static Date dtLastMonthDate{get;set;}
    private static Boolean isDistrubuted{get; set;}   
    private static Boolean DisableDistribute{get; set;}   
    private static final string SUCCESS_SAVE = 'Monthy Expected Values Successfully saved.';

    @auraenabled  
    public static map<string,object>  getMonthlyValues(string recordId) {
        list<Monthly_Expected_Values__c> lMonthlyValues ;
        list<wrapMonthlyValues> lvaluesWrap =new list<wrapMonthlyValues>();
        list<wrapMonthlyValues> lvaluesSummaryWrap =new list<wrapMonthlyValues>();
        map<string,object> lreturn = new map<string,object>{'errors'=> new list<string>() ,  'values'=> new list<wrapMonthlyValues>() , 'summary'=> new list<wrapMonthlyValues>(), 'isEditVolume' =>true };
        wrapMonthlyValues it_temp;
        lMonthlyValues = showDistribution(recordid);
        integer intA=0;
        for(Monthly_Expected_Values__c i: lMonthlyValues){
            Datetime output = Datetime.newInstanceGmt(i.date__c, Time.newInstance(0,0,0,0));
            string strname = output.formatGmt('MMM-YYYY');

            it_temp = new wrapMonthlyValues();
            it_temp.DateValue = strname;
            it_temp.Volume = i.Volumes__c;
            it_temp.GM = i.GM__c;
            it_temp.PM = i.PM__c;
            it_temp.Id = i.Id==null?''+intA:''+i.Id;
            it_temp.newRecord = i.Id==null;
            it_temp.record= i;

            lvaluesWrap.add(it_temp);
            intA++;
        }     

        it_temp =  new wrapMonthlyValues();
        it_temp.DateValue = totalFY1Name;
        it_temp.Volume =  totalVolumeFY1;
        it_temp.GM = totalGMFY1;
        it_temp.PM = totalPMFY1;
        lvaluesSummaryWrap.add(it_temp);

        it_temp =  new wrapMonthlyValues();
        it_temp.DateValue = totalFY2Name;
        it_temp.Volume =  totalVolumeFY2;
        it_temp.GM = totalGMFY2;
        it_temp.PM = totalPMFY2;
        lvaluesSummaryWrap.add(it_temp);

        it_temp =  new wrapMonthlyValues();
        it_temp.DateValue = 'Grand Total:' ;
        it_temp.Volume =  totalVolume;
        it_temp.GM = totalGM;
        it_temp.PM = totalPM;
        lvaluesSummaryWrap.add(it_temp);
        

        lreturn.put('values', lvaluesWrap );
        lreturn.put('summary', lvaluesSummaryWrap );
        lreturn.put('isEditVolume', !DisableDistribute );

        system.debug('lreturn:' + lreturn);
        return lreturn ;
    }
    private static boolean getDisableDistribute(opportunity action ){
        string strRoleName ;
        if(action.stageName == 'Engage and grow' && !(showExpectedDetails())){
            return true;        
        }
        strRoleName = [Select Id,Name from UserRole where Id=:userinfo.getUserRoleId()].Name;
        if(((action.Approval_Status__c == 'Pending Planned Action Approval') || (action.Approval_Status__c == 'Pending Implemented Action Approval') || (action.Approval_Status__c == 'Pending Engage and grow Approval')) &&  !(strRoleName.equalsIgnoreCase('ARP Global') || strRoleName.equalsIgnoreCase('ARPNA DP Sales: Distribution Director') || strRoleName.equalsIgnoreCase('ARPNA DP Sales: HC Director') || strRoleName.equalsIgnoreCase('ARPNA DP Sales VP') && strRoleName.equalsIgnoreCase('ARPNA DP Sales: SWB Director') || strRoleName.equalsIgnoreCase('ARPNA DP Finance') || strRoleName.equalsIgnoreCase('ARPNA Bev Finance'))){
             return true; 
        }
        return false;             
    }
    public static boolean showExpectedDetails(){
        boolean showExpectedDetails = false;
        string strRoleName = '';
        string strProfileName = [Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;
        Exp_Details_Monthly_Values_Permision__c objCustSettingAllowedProfiles = Exp_Details_Monthly_Values_Permision__c.getOrgDefaults();
        if(objCustSettingAllowedProfiles != null && String.IsNotBlank(objCustSettingAllowedProfiles.Monthly_Values_Profiles__c)){
            Set<String> SetProfileName = New Set<String>();
            for(String strProfile : objCustSettingAllowedProfiles.Monthly_Values_Profiles__c.Split(',')){
                 SetProfileName.add(strProfile);       
            }                    
            
            if(SetProfileName.Contains(strProfileName)){
                isPermittedProfile = true;
                showExpectedDetails = true;
            }           
        }
        
        Id roleId =userinfo.getUserRoleId();
        if(String.IsNotBlank(roleId)){
           strRoleName=[Select Id,Name from UserRole where Id=:roleId].Name;
        }       
        if(objCustSettingAllowedProfiles != null && String.IsNotBlank(objCustSettingAllowedProfiles.Exp_Details_Roles__c)){
            Set<String> SetRoleName = New Set<String>();
            for(String strRole : objCustSettingAllowedProfiles.Exp_Details_Roles__c.Split(',')){
                 SetRoleName.add(strRole);       
            }              
            if(String.IsNotBlank(roleId) && SetRoleName.Contains(strRoleName)){
                showExpectedDetails = true;
            }                          
        }
        return showExpectedDetails;
    }

    
    @auraenabled 
    public static map<string,object> saveDistribute(id recordid ){
        map<string,object> mreturn = new map<string,object>{'errors'=> new list<string>(), 'success'=> new list<string>()};

        try{
            distribute(new set<id>{recordid},true,null,null);
            mreturn.put('success' , new list<string>{SUCCESS_SAVE});
            map<string,object> omonthly = getMonthlyValues(recordid);
            mreturn.put('values' ,   omonthly.get('values') );
            mreturn.put('summary' , omonthly.get('summary'));

            
        }catch(exception e){
            system.debug('saveDistribute_error:'+ e.getStackTraceString() +  '>>' + e.getMessage());
            mreturn.put('errors', new list<string>{'error: ' + e.getStackTraceString() +  '>>' + e.getMessage()});
            return mreturn;
        }
        return mreturn;
    }
    @auraenabled 
    public static map<string,object> saveMonthlyValues(string recordid , object objData, object objDraftValues){
        List<wrapMonthlyValues> lMonthyValues;
        List<wrapMonthlyValues> lDraftValues;
        list<Monthly_Expected_Values__c> ltoUpsert = new list<Monthly_Expected_Values__c>();
        map<string, boolean> mSuccesssaved = new map<string,boolean>{'isvalidTotal'=>false, 'showReasonforLosses'=>false};
        map<string,object> mreturn = new map<string,object>{'errors'=> new list<string>(), 'success'=> new list<string>(), 'isEditVolume' =>true, 'showReasonforLosses'=>false, 'messageReasonforLosses'=> new list<string>() };

        try{
            lMonthyValues = (List<wrapMonthlyValues>) JSON.deserialize(JSON.serialize(objData),List<wrapMonthlyValues>.class );
            lDraftValues = (List<wrapMonthlyValues>) JSON.deserialize(JSON.serialize(objDraftValues),List<wrapMonthlyValues>.class );
    
            for(wrapMonthlyValues draft: lDraftValues){
                for(wrapMonthlyValues values: lMonthyValues){
                    if(values.id.trim().toLowerCase() == draft.id.trim().toLowerCase()){
                        values.record.put('Volumes__c',draft.Volume);                    
                    }
                }
            }
            for(wrapMonthlyValues values: lMonthyValues){
                ltoUpsert.add(values.record);
            }
    
            mSuccesssaved = saveExpectedValues(ltoUpsert,recordid);
            
            if(!mSuccesssaved.get('isvalidTotal')){
                mreturn.put('errors' , new list<string>{'Grand Total of Volume should match with Expected Units Annually.'});
            }else{
                mreturn.put('success' , new list<string>{SUCCESS_SAVE});
            }

            map<string,object> omonthly = getMonthlyValues(recordid);
            mreturn.put('showReasonforLosses' , mSuccesssaved.get('showReasonforLosses'));
            mreturn.put('messageReasonforLosses' , new list<string>{'Please review Business Loss Information Section'});
            mreturn.put('values' ,  omonthly.get('values') );
            mreturn.put('summary' , omonthly.get('summary'));
            mreturn.put('isEditVolume', !DisableDistribute );
            
            return mreturn;
    
        }catch(exception e){
            system.debug('error: ' + e.getStackTraceString() +  '>>' + e.getMessage());
            
            mreturn.put('errors', new list<string>{ARP_Utils.translateDMLError(e,e.getMessage() )});
            return mreturn;
        }

    }
    
    public static  map<string, boolean> saveExpectedValues(list<Monthly_Expected_Values__c> lstMontlyExpected, id recordId ){
        map<string, boolean> mreturn = new map<string,boolean>{'isvalidTotal'=>true, 'showReasonforLosses'=>false};
        totalVolume = 0;  
        totalGM = 0;  
        totalPM = 0;    
        totalVolumeFY1 = 0.00;
        totalGMFY1 = 0.00;
        totalPMFY1 = 0.00;      
        totalVolumeFY2 = 0.00;
        totalGMFY2 = 0.00;
        totalPMFY2 = 0.00;  
        totalFY1Name = ''    ;
        totalFY2Name = ''    ;

        Boolean isValidTotal = true;
        opportunity action = getOpportunityandSetValue(new set<id>{recordId}, null, null).get(recordId);
        for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
            objMonthlyExpected.Volumes__c = (objMonthlyExpected.Volumes__c == null || String.IsBlank(String.ValueOf(objMonthlyExpected.Volumes__c)) ? 0 : objMonthlyExpected.Volumes__c);
            if(objMonthlyExpected.InScope__c){
                objMonthlyExpected.GM__c = ((action.Expected_Gross_Margin__c == null ? 0 : action.Expected_Gross_Margin__c) * objMonthlyExpected.Volumes__c );
                objMonthlyExpected.PM__c = ((action.Expected_PM_K__c == null ? 0 : action.Expected_PM_K__c) * objMonthlyExpected.Volumes__c );                
            }
            
            totalVolume = totalVolume + objMonthlyExpected.Volumes__c.setscale(3);
            totalGM = totalGM + objMonthlyExpected.GM__c.setscale(2);
            totalPM = totalPM + objMonthlyExpected.PM__c.setscale(2);
            
            if(objMonthlyExpected.Date__c.Month() < 7 && totalFY1Name.equalsIgnoreCase(String.ValueOf(objMonthlyExpected.Date__c.Year()))){
                        totalVolumeFY1 = totalVolumeFY1 + objMonthlyExpected.Volumes__c.setscale(3);
                        totalGMFY1 = totalGMFY1 + objMonthlyExpected.GM__c.setscale(2);
                        totalPMFY1 = totalPMFY1 + objMonthlyExpected.PM__c.setscale(2);     
            }
            else if(objMonthlyExpected.Date__c.Month() >= 7 && totalFY1Name.equalsIgnoreCase(String.ValueOf(objMonthlyExpected.Date__c.Year() +1 ))){
                totalVolumeFY1 = totalVolumeFY1 + objMonthlyExpected.Volumes__c.setscale(3);
                totalGMFY1 = totalGMFY1 + objMonthlyExpected.GM__c.setscale(2);
                totalPMFY1 = totalPMFY1 + objMonthlyExpected.PM__c.setscale(2);     
            }
            else {
                totalVolumeFY2 = totalVolumeFY2 + objMonthlyExpected.Volumes__c.setscale(3);
                totalGMFY2 = totalGMFY2 + objMonthlyExpected.GM__c.setscale(2);
                totalPMFY2 = totalPMFY2 + objMonthlyExpected.PM__c.setscale(2);     
            }
        }
        
        totalVolume = totalVolume.setscale(3);
        totalGM = totalGM.setscale(2);
        totalPM = totalPM.setscale(2);
        
        totalVolumeFY1 = totalVolumeFY1.setscale(3);
        totalGMFY1 = totalGMFY1.setscale(2);
        totalPMFY1 = totalPMFY1.setscale(2);

        totalVolumeFY2 = totalVolumeFY2.setscale(3);
        totalGMFY2 = totalGMFY2.setscale(2);
        totalPMFY2 = totalPMFY2.setscale(2);
                
        if(action.Expected_Units_Annually__c != null && totalVolume != action.Expected_Units_Annually__c){
            action.Expected_Units_Annually__c = totalVolume;
        }
         
        if(totalGM != 0){
            action.Exp_Gross_Margin_Annually__c = totalGM;
        }
        if(totalPM != 0){
            action.Unadj_Expected_Annual_Impact__c = totalPM;
        }

        if(isValidTotal){           
            action.FY1ExpectedUnit__c = totalVolumeFY1;
            action.FY2ExpectedUnit__c = totalVolumeFY2;
            action.FY1Name__c = totalFY1Name;
            action.FY2Name__c = totalFY2Name;    
            boolean showReasonforLosses =  CheckReasonforLosses(action);
            mreturn.put('showReasonforLosses' , showReasonforLosses );             
            if( showReasonforLosses)  {
                setDefaultReasonforLosses(action);
            }
            system.debug('action:' + action);
            upsert(action);     
            for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
                objMonthlyExpected.Action1__c = action.id;
                objMonthlyExpected.CurrencyIsoCode = action.CurrencyIsoCode;
            }
            upsert(lstMontlyExpected);      
            system.debug('lstMontlyExpected: '+ lstMontlyExpected);
        }else{
            //isDisplayWarning = true;
        }
        system.debug('isValidTotal:' + isValidTotal);
        mreturn.put('isvalidTotal' ,isValidTotal );
        return mreturn;
    }
    private static void setDefaultReasonforLosses(Opportunity action){
        action.Reason_for_Losses_Primary__c = 'Other';
        action.Reason_for_Losses_Sub_Primary__c = 'Unknown';
        action.Business_lost_comment__c = 'Unknown';
    }
    private static boolean CheckReasonforLosses(opportunity action){
        return ( (action.Expected_PM_K__c <0 || action.Expected_Units_Annually__c <0 ) && action.Reason_for_Losses_Primary__c==null)  ;
    }
    public static List<Monthly_Expected_Values__c> showDistribution(string recordId){
        list<opportunity> lstactions = [select Id,Expected_Units_Annually__c,Benefit_End_Date__c,Approval_Status__c,stageName,CloseDate from Opportunity where id=: recordid];
        opportunity action = lstactions.size()==0?new Opportunity():lstactions[0];
        List<Monthly_Expected_Values__c>  lstMontlyExpected;
        boolean shouldaddMonthly = false;
        integer intIndex = 0;

        isPermittedProfile = false;
        totalVolume = 0.00;
        totalGM = 0.00;
        totalPM = 0.00;
        
        totalFY1Name = '';
        totalFY2Name = '';
        
        totalVolumeFY1 = 0.00;
        totalGMFY1 = 0.00;
        totalPMFY1 = 0.00;
        
        totalVolumeFY2 = 0.00;
        totalGMFY2 = 0.00;
        totalPMFY2 = 0.00;

       
        lstMontlyExpected = new List<Monthly_Expected_Values__c>();
        System.Debug('####ACTIONID' + action.id);
        if(action.id != null) {
            lstMontlyExpected =  [Select Id, Name, Date__c,Volumes__c, GM__c, PM__c, Distributed__c, InScope__c,InRange__c
                                From Monthly_Expected_Values__c 
                                Where Action1__c =:action.id Order By Date__c];
            double totSum = 0;

            if(action.Expected_Units_Annually__c>0){
                for(Monthly_Expected_Values__c it : lstMontlyExpected){
                    totSum = totSum + it.Volumes__c;
                }
                if (totSum==0){
                    shouldaddMonthly=true;
                }

            }

                                
        }
                                
        if(lstMontlyExpected.size() == 0 || shouldaddMonthly ==true ){
            shouldaddMonthly=true;
            Integer intDateDiff = (action.Benefit_End_Date__c == null || action.CloseDate == null ? 12 : (action.CloseDate.monthsBetween(action.Benefit_End_Date__c)));
            Integer intMonthConsideration = (intDateDiff < 0 || intDateDiff >= 12? 12 : intDateDiff + 1);                             
            Integer intMonth = (action.CloseDate != null ? action.CloseDate.Month() : Date.Today().Month());
            Integer intYear = (action.CloseDate != null ? action.CloseDate.Year() : Date.Today().Year());
            integer intCounter;
            
            if(intMonth < 7){
                totalFY1Name = String.ValueOf(intYear);
                totalFY2Name = String.ValueOf((intYear + 1));
            }else{
                totalFY1Name = String.ValueOf(intYear + 1);
                totalFY2Name = String.ValueOf((intYear + 2));
            }        
        
            for(intCounter=0; intCounter<12; intCounter++){                    
                String strMonthDate = '';            
                DateTime dtfirstDate = DateTime.newInstance(intYear, intMonth, 1);          
                String strDayName = dtfirstDate.format('EEEE');
                if(strDayName.equalsIgnoreCase('Monday')){
                    strMonthDate = intYear + '-' + intMonth  + '-05';               
                }else if(strDayName.equalsIgnoreCase('Sunday')){
                    strMonthDate = intYear + '-' + intMonth  + '-06';
                }else{
                    strMonthDate = intYear + '-' + intMonth  + '-07';
                }                           
                Date dtMonthDate = date.valueOf(strMonthDate); 
                
                Monthly_Expected_Values__c objMonthlyExpected = New Monthly_Expected_Values__c();
                objMonthlyExpected.Date__c = dtmonthDate;
                objMonthlyExpected.Volumes__c = 0;
                objMonthlyExpected.GM__c = 0;
                objMonthlyExpected.PM__c = 0;
                objMonthlyExpected.Action1__c = action.id;
                objMonthlyExpected.Distributed__c = false;                              
                
                if(intMonthConsideration <= 0){
                    objMonthlyExpected.InScope__c= false;
                    objMonthlyExpected.inRange__c = false;
                }else{
                    objMonthlyExpected.InScope__c= true;
                    objMonthlyExpected.inRange__c = true;
                }

                intMonthConsideration--;
                lstMontlyExpected.add(objMonthlyExpected);
                if(intMonth == 12){
                    intMonth = 1;
                    intYear++;
                }
                else{
                    intMonth++;
                }
            }
            isDistrubuted = false;
        }else{        
            //Decimal dectotalVolume = 0.00;            
            Integer intYear = lstMontlyExpected[0].Date__c.Year();
            Integer intMonth = lstMontlyExpected[0].Date__c.Month();
            
            if(intMonth < 7){
                totalFY1Name = String.ValueOf(intYear);
                totalFY2Name = String.ValueOf((intYear + 1));
            }else{
                totalFY1Name = String.ValueOf(intYear + 1);
                totalFY2Name = String.ValueOf((intYear + 2));
            }
                   
            for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
                    totalVolume = totalVolume + objMonthlyExpected.Volumes__c.setscale(3);
                    totalGM = totalGM + objMonthlyExpected.GM__c.setscale(2);
                    totalPM = totalPM + objMonthlyExpected.PM__c.setscale(2);
                    
                    if(objMonthlyExpected.Date__c.Month() < 7 && totalFY1Name.equalsIgnoreCase(String.ValueOf(objMonthlyExpected.Date__c.Year()))){
                        totalVolumeFY1 = totalVolumeFY1 + objMonthlyExpected.Volumes__c.setscale(3);
                        totalGMFY1 = totalGMFY1 + objMonthlyExpected.GM__c.setscale(2);
                        totalPMFY1 = totalPMFY1 + objMonthlyExpected.PM__c.setscale(2);     
                    }
                    else if(objMonthlyExpected.Date__c.Month() >= 7 && totalFY1Name.equalsIgnoreCase(String.ValueOf(objMonthlyExpected.Date__c.Year() +1 ))){
                        totalVolumeFY1 = totalVolumeFY1 + objMonthlyExpected.Volumes__c.setscale(3);
                        totalGMFY1 = totalGMFY1 + objMonthlyExpected.GM__c.setscale(2);
                        totalPMFY1 = totalPMFY1 + objMonthlyExpected.PM__c.setscale(2);     
                    }
                    else {
                        totalVolumeFY2 = totalVolumeFY2 + objMonthlyExpected.Volumes__c.setscale(3);
                        totalGMFY2 = totalGMFY2 + objMonthlyExpected.GM__c.setscale(2);
                        totalPMFY2 = totalPMFY2 + objMonthlyExpected.PM__c.setscale(2);     
                    }
            }
            totalVolume = totalVolume.setscale(3);
            totalGM = totalGM.setscale(2);
            totalPM = totalPM.setscale(2);
            
            totalVolumeFY1 = totalVolumeFY1.setscale(3);
            totalGMFY1 = totalGMFY1.setscale(2);
            totalPMFY1 = totalPMFY1.setscale(2);

            totalVolumeFY2 = totalVolumeFY2.setscale(3);
            totalGMFY2 = totalGMFY2.setscale(2);
            totalPMFY2 = totalPMFY2.setscale(2);
            
            if(lstMontlyExpected[0].Distributed__c){
                isDistrubuted = true;           
            }else{
                isDistrubuted = false;          
            }
        }
        String strMonthDate = '';
        Date dtLastDate = lstMontlyExpected[lstMontlyExpected.size()-1].Date__c.addMonths(1);
        DateTime dtTimeLastDate = DateTime.newInstance(dtLastDate.Year(), dtLastDate.Month(), 1);           
        String strDayName = dtTimeLastDate.format('EEEE');
        if(strDayName.equalsIgnoreCase('Monday')){
            strMonthDate = dtLastDate.Year() + '-' + dtLastDate.Month()  + '-05';               
        }else if(strDayName.equalsIgnoreCase('Sunday')){
            strMonthDate = dtLastDate.Year() + '-' + dtLastDate.Month()  + '-06';
        }else{
            strMonthDate = dtLastDate.Year() + '-' + dtLastDate.Month()  + '-07';
        }                   
        dtLastMonthDate = date.valueOf(strMonthDate);

        System.debug('dtLastMonthDate====' + dtLastMonthDate);
        System.debug('dtLastDate====' + dtLastDate);
        integer rowNum = 0;
        for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
            if(objMonthlyExpected.InRange__c){
                objMonthlyExpected.InScope__c = true;
            }
        }
        for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
            if(action.stageName == 'Engage and grow' && !(isPermittedProfile)){
                if((!(rowNum <=10) && objMonthlyExpected.InRange__c && !(Date.Today() < dtLastMonthDate)) || (rowNum <=10 && objMonthlyExpected.InRange__c && !(Date.Today() < lstMontlyExpected[rowNum+ 1].Date__c))){
                            objMonthlyExpected.InScope__c = false;
                            System.debug('objMonthlyExpected.InScope__c====' + objMonthlyExpected.InRange__c + '==rowNum==' + rowNum);              
                }
                
            }
            rowNum++;
        }      
        DisableDistribute = getDisableDistribute(action) ;
        if(shouldaddMonthly){
            distribute(new set<id>{recordId},true,null,null);
            return showDistribution(recordId);
        }
        return lstMontlyExpected;
    }  
    public static map<id,Opportunity> getOpportunityandSetValue(set<id> recordIds,  map<id,sobject> mCurrentOppts, set<string> fieldlisttoCheck){
        map<id,opportunity> mActions ;
        decimal decResinCostk = 0;
        string strProfileName;
        mActions = new map<id,opportunity>([select Id,Business_lost_comment__c ,Reason_for_Losses_Primary__c,Reason_for_Losses_Sub_Primary__c,Unadj_Expected_Annual_Impact__c,Cost_to_Produce_k__c,Business_Unit__c,Exp_Gross_Margin_Annually__c,Selling_Price__c,Other_Material_k__c,Business_Group__c,Division__c,Benefit_End_Date__c,Base_Resin_Price_Units_lb__c,Approx_Gram_Weight__c, CurrencyIsoCode,Expected_Gross_Margin__c,stageName,CloseDate,Expected_PM_K__c,Expected_Units_Annually__c,FY1ExpectedUnit__c,FY2ExpectedUnit__c,FY1Name__c,FY2Name__c from Opportunity where id in: recordIds]);
        system.debug('mActions:' + mActions?.values());
        strProfileName = [Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;

        for(Opportunity action: mActions.values() ){
            if(fieldlisttoCheck!=null){
                for(string s: fieldlisttoCheck){
                    if(mCurrentOppts?.get(action.id)?.isset(s)){
                        action.put(s , mCurrentOppts?.get(action.id)?.get(s) );
                    }                    
                }
            }
         
            
            decResinCostk = ((action.Base_Resin_Price_Units_lb__c == null ? 0 : action.Base_Resin_Price_Units_lb__c) * (action.Approx_Gram_Weight__c == null ? 0 : action.Approx_Gram_Weight__c) * 2.205);
            decResinCostk = decResinCostk.setscale(2);         
         
            if (action.Business_Group__c.equalsIgnoreCase('Amcor Rigid Packaging') && action.Division__c.equalsIgnoreCase('Beverage ARP')){
                
                action.Expected_Gross_Margin__c = (action.Selling_Price__c == null ? 0 : action.Selling_Price__c) - decResinCostk - 
                                                 (action.Other_Material_k__c  == null ? 0 : action.Other_Material_k__c);
                                                 
                action.Exp_Gross_Margin_Annually__c = (action.Expected_Gross_Margin__c == null ? 0 : action.Expected_Gross_Margin__c) * 
                                                     (action.Expected_Units_Annually__c == null ? 0 : action.Expected_Units_Annually__c);
    
                action.Expected_PM_K__c = (action.Expected_Gross_Margin__c == null ? 0 : action.Expected_Gross_Margin__c) - 
                                         (action.Cost_to_Produce_k__c == null ? 0  : action.Cost_to_Produce_k__c);
                action.Unadj_Expected_Annual_Impact__c = (action.Expected_PM_K__c == null ? 0 : action.Expected_PM_K__c) * 
                                                        (action.Expected_Units_Annually__c == null ? 0 : action.Expected_Units_Annually__c);            
                      
            }else if (action.Business_Group__c.equalsIgnoreCase('Amcor Rigid Packaging') && (action.Division__c.equalsIgnoreCase('SC')|| action.Business_Unit__c.equalsIgnoreCase('LATAM'))){
                action.Exp_Gross_Margin_Annually__c = (action.Expected_Gross_Margin__c == null ? 0 : action.Expected_Gross_Margin__c) * 
                                     (action.Expected_Units_Annually__c == null ? 0 : action.Expected_Units_Annually__c);
                action.Unadj_Expected_Annual_Impact__c = (action.Expected_PM_K__c == null ? 0 : action.Expected_PM_K__c) * 
                                        (action.Expected_Units_Annually__c == null ? 0 : action.Expected_Units_Annually__c);
            }             
                      
            
            Exp_Details_Monthly_Values_Permision__c objCustSettingAllowedProfiles = Exp_Details_Monthly_Values_Permision__c.getOrgDefaults();
            if(objCustSettingAllowedProfiles != null && String.IsNotBlank(objCustSettingAllowedProfiles.Monthly_Values_Profiles__c)){
                Set<String> SetProfileName = New Set<String>();
                for(String strProfile : objCustSettingAllowedProfiles.Monthly_Values_Profiles__c.Split(',')){
                     SetProfileName.add(strProfile);       
                }                
                if(SetProfileName.Contains(strProfileName)){
                    isPermittedProfile = true;
                }
            }
        }
            
        return mActions;
            
    }
    public static map<id,sobject> distribute(set<id> recordIds, boolean performDLMOperation, map<id,sobject> mCurrentOppts, set<string> fieldlisttoCheck){
        
        List<Monthly_Expected_Values__c>  lstMontlyExpected = new List<Monthly_Expected_Values__c>();
        List<Monthly_Expected_Values__c> lstMontlyExpectedOldVal = new List<Monthly_Expected_Values__c>();       
        map<id, list<Monthly_Expected_Values__c>> mMonthlyValues;
        map<id,Opportunity> mOpptstoUpdate;
        map<id,sobject> mobjectstoUpsert = new map<id,sobject>();

        mOpptstoUpdate = getOpportunityandSetValue(recordIds,mCurrentOppts,fieldlisttoCheck);
        mMonthlyValues = getAllMonthlyValues(recordIds);
        for(opportunity action : mOpptstoUpdate.values()){
            lstMontlyExpectedOldVal = new List<Monthly_Expected_Values__c>();       
            lstMontlyExpected = new List<Monthly_Expected_Values__c>();
            totalVolume = 0.00;
            totalGM = 0.00;
            totalPM = 0.00;        
            totalFY1Name = '';
            totalFY2Name = '';        
            totalVolumeFY1 = 0.00;
            totalGMFY1 = 0.00;
            totalPMFY1 = 0.00;        
            totalVolumeFY2 = 0.00;
            totalGMFY2 = 0.00;
            totalPMFY2 = 0.00;
            Decimal decTotalOldVolume = 0.00;
            Integer intLastInScopeIndex = 0;
            Integer intDateDiff = 0;
            Integer intMonthConsideration = 0;
            Integer intMonth = 0;
            Integer intYear = 0;
            Integer intDateDiffAdd = 0;
            if((action.stageName == 'Engage and grow' && !isPermittedProfile)){
                DateTime dtTodayDate = DateTime.newInstance(Date.Today().Year(), Date.Today().Month(), 1);
                String strTodayDayName = dtTodayDate.format('EEEE');
                String strTodayMonthDate = '';
                if(strTodayDayName.equalsIgnoreCase('Monday')){
                    strTodayMonthDate = Date.Today().Year() + '-' + Date.Today().Month()  + '-05';               
                }else if(strTodayDayName.equalsIgnoreCase('Sunday')){
                    strTodayMonthDate = Date.Today().Year() + '-' + Date.Today().Month()  + '-06';
                }else{
                    strTodayMonthDate = Date.Today().Year() + '-' + Date.Today().Month()  + '-07';
                }
                Date dtTodayMonthDate = date.valueOf(strTodayMonthDate);
    
                if(Date.Today() < dtTodayMonthDate){
                    lstMontlyExpectedOldVal= getMonthlyValuesLASTMONTH(action.id, mMonthlyValues);
                }else{
                    lstMontlyExpectedOldVal = getMonthlyValuesTHISMONTH(action.id, mMonthlyValues);
                }
            }              

            for(Monthly_Expected_Values__c objMonthly : lstMontlyExpectedOldVal){
                decTotalOldVolume = decTotalOldVolume + objMonthly.Volumes__c;
            }
                            
            intDateDiff = (action.Benefit_End_Date__c == null || action.CloseDate == null ? 12 : (action.CloseDate.monthsBetween(action.Benefit_End_Date__c)));
            intMonthConsideration = (intDateDiff < 0 || intDateDiff >= 12? 12 : intDateDiff + 1);                             
            intMonth = (action.CloseDate != null ? action.CloseDate.Month() : Date.Today().Month());
            intYear = (action.CloseDate != null ? action.CloseDate.Year() : Date.Today().Year());
            if((action.stageName == 'Engage and grow' && !isPermittedProfile) && action.CloseDate != null && action.CloseDate < Date.Today()){            
                intDateDiffAdd = (action.CloseDate.monthsBetween(Date.Today()));
                intDateDiffAdd = (intDateDiffAdd < 0 ? 0 : (intDateDiffAdd >= 12? 12 : intDateDiffAdd));
                DateTime dtfirstDate = DateTime.newInstance(Date.Today().Year(), Date.Today().Month(), 1);
                String strDayName = dtfirstDate.format('EEEE');
                String strMonthDate = '';
                if(strDayName.equalsIgnoreCase('Monday')){
                    strMonthDate = Date.Today().Year() + '-' + Date.Today().Month()  + '-05';               
                }else if(strDayName.equalsIgnoreCase('Sunday')){
                    strMonthDate = Date.Today().Year() + '-' + Date.Today().Month()  + '-06';
                }else{
                    strMonthDate = Date.Today().Year() + '-' + Date.Today().Month()  + '-07';
                }
                Date dtMonthDate = date.valueOf(strMonthDate);
                
                if(Date.Today() < dtMonthDate){
                        intDateDiffAdd = intDateDiffAdd -1;         
                }
            }
                    
            intMonthConsideration = intMonthConsideration - intDateDiffAdd;
            if(intMonth < 7){
                totalFY1Name = String.ValueOf(intYear);
                totalFY2Name = String.ValueOf((intYear + 1));
            }else{
                totalFY1Name = String.ValueOf(intYear + 1);
                totalFY2Name = String.ValueOf((intYear + 2));
            }
            
            Integer intCounter;     
            Decimal decUnitsPrecision = ((action.Expected_Units_Annually__c == null ?  0 : action.Expected_Units_Annually__c- decTotalOldVolume) / (intMonthConsideration <=0 ? 1 : intMonthConsideration));
            Decimal decUnits = decUnitsPrecision.setscale(3);
            Double decGM = 0;
            Double decPM = 0;
            
            for(intCounter=0;intCounter<intDateDiffAdd; intCounter++){                 
                String strMonthDate = '';
    
                DateTime dtfirstDate = DateTime.newInstance(intYear, intMonth, 1);          
                String strDayName = dtfirstDate.format('EEEE');
                if(strDayName.equalsIgnoreCase('Monday')){
                    strMonthDate = intYear + '-' + intMonth  + '-05';               
                }else if(strDayName.equalsIgnoreCase('Sunday')){
                    strMonthDate = intYear + '-' + intMonth  + '-06';
                }else{
                    strMonthDate = intYear + '-' + intMonth  + '-07';
                }
                            
                Date dtMonthDate = date.valueOf(strMonthDate);            
                Monthly_Expected_Values__c objMonthlyExpected = New Monthly_Expected_Values__c();
                objMonthlyExpected.Date__c = dtMonthDate;
                objMonthlyExpected.Distributed__c = true;
                objMonthlyExpected.Volumes__c = (lstMontlyExpectedOldVal != null && lstMontlyExpectedOldVal.size() > 0 ? lstMontlyExpectedOldVal[intCounter].Volumes__c : 0);
                objMonthlyExpected.GM__c = (lstMontlyExpectedOldVal != null && lstMontlyExpectedOldVal.size() > 0 ? lstMontlyExpectedOldVal[intCounter].GM__c : 0);
                objMonthlyExpected.PM__c = (lstMontlyExpectedOldVal != null && lstMontlyExpectedOldVal.size() > 0 ? lstMontlyExpectedOldVal[intCounter].PM__c : 0);
                objMonthlyExpected.InScope__c= true;
    
                lstMontlyExpected.add(objMonthlyExpected);
                if(intMonth == 12){
                    intMonth = 1;
                    intYear++;
                }
                else{
                    intMonth++;
                }           
            }
            
            for(intCounter=lstMontlyExpected.size(); intCounter<12; intCounter++){                 
                String strMonthDate = '';
                
                DateTime dtfirstDate = DateTime.newInstance(intYear, intMonth, 1);          
                String strDayName = dtfirstDate.format('EEEE');
                if(strDayName.equalsIgnoreCase('Monday')){
                    strMonthDate = intYear + '-' + intMonth  + '-05';               
                }else if(strDayName.equalsIgnoreCase('Sunday')){
                    strMonthDate = intYear + '-' + intMonth  + '-06';
                }else{
                    strMonthDate = intYear + '-' + intMonth  + '-07';
                }
                            
                Date dtMonthDate = date.valueOf(strMonthDate);            
                Monthly_Expected_Values__c objMonthlyExpected = New Monthly_Expected_Values__c();
                objMonthlyExpected.Date__c = dtMonthDate;
                objMonthlyExpected.Distributed__c = true;
                System.debug('===Loop.intMonthConsideration==' + intMonthConsideration);                    
                if(intMonthConsideration <= 0){
                    objMonthlyExpected.Volumes__c = 0;
                    objMonthlyExpected.GM__c = 0;
                    objMonthlyExpected.PM__c = 0;
                    objMonthlyExpected.InScope__c= false;
    
                }else{
                    objMonthlyExpected.Volumes__c = decUnits;
    
                    decGM = ((action.Expected_Gross_Margin__c == null ? 0 : action.Expected_Gross_Margin__c) * decUnits );
                    decPM = ((action.Expected_PM_K__c == null ? 0 : action.Expected_PM_K__c) * decUnits );
                    objMonthlyExpected.GM__c = decGM;
                    objMonthlyExpected.PM__c = decPM;                           
                    objMonthlyExpected.InScope__c= true;
                }           
                lstMontlyExpected.add(objMonthlyExpected);
                intMonthConsideration--;
                if(intMonth == 12){
                    intMonth = 1;
                    intYear++;
                }
                else{
                    intMonth++;
                }           
            }
            String strMonthDate = '';
            DateTime dtfirstDate = DateTime.newInstance(intYear, intMonth, 1);          
            String strDayName = dtfirstDate.format('EEEE');
            if(strDayName.equalsIgnoreCase('Monday')){
                strMonthDate = intYear + '-' + intMonth  + '-05';               
            }else if(strDayName.equalsIgnoreCase('Sunday')){
                strMonthDate = intYear + '-' + intMonth  + '-06';
            }else{
                strMonthDate = intYear + '-' + intMonth  + '-07';
            }                   
            dtLastMonthDate = date.valueOf(strMonthDate);
            
            integer intIndexCounter = 0;
            for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
                    totalVolume = totalVolume + objMonthlyExpected.Volumes__c.setscale(3);                
                    if(objMonthlyExpected.InScope__c){
                        intLastInScopeIndex = intIndexCounter;
                    }
                    intIndexCounter= intIndexCounter+1;             
            }
            totalVolume = totalVolume.setscale(3);
           
            
            if(totalVolume != action.Expected_Units_Annually__c){
                
                decUnits = (lstMontlyExpected[intLastInScopeIndex].Volumes__c==null?0:lstMontlyExpected[intLastInScopeIndex].Volumes__c) - ( (totalVolume==null?0:totalVolume) - (action.Expected_Units_Annually__c==null?0:action.Expected_Units_Annually__c) );
                decUnits = decUnits.setscale(3);
                decGM = ((action.Expected_Gross_Margin__c == null ? 0 : action.Expected_Gross_Margin__c) * decUnits );
                decPM = ((action.Expected_PM_K__c == null ? 0 : action.Expected_PM_K__c) * decUnits );
                lstMontlyExpected[intLastInScopeIndex].Volumes__c = decUnits;           
                lstMontlyExpected[intLastInScopeIndex].GM__c = decGM;
                lstMontlyExpected[intLastInScopeIndex].PM__c = decPM;                
            }
            
            for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
                    totalGM = totalGM + objMonthlyExpected.GM__c.setscale(2);
                    totalPM = totalPM + objMonthlyExpected.PM__c.setscale(2);
                    
                    if(objMonthlyExpected.Date__c.Month() < 7 && totalFY1Name.equalsIgnoreCase(String.ValueOf(objMonthlyExpected.Date__c.Year()))){
                        totalVolumeFY1 = totalVolumeFY1 + objMonthlyExpected.Volumes__c.setscale(3);
                    }
                    else if(objMonthlyExpected.Date__c.Month() >= 7 && totalFY1Name.equalsIgnoreCase(String.ValueOf(objMonthlyExpected.Date__c.Year() +1 ))){
                        totalVolumeFY1 = totalVolumeFY1 + objMonthlyExpected.Volumes__c.setscale(3);
                    }
                    else {
                        totalVolumeFY2 = totalVolumeFY2 + objMonthlyExpected.Volumes__c.setscale(3);
                    }
            }
            totalGM = totalGM.setscale(2);
            totalPM = totalPM.setscale(2);
            totalVolumeFY1 = totalVolumeFY1.setscale(3);
            totalVolumeFY2 = totalVolumeFY2.setscale(3);
            if(totalGM != 0){
                action.Exp_Gross_Margin_Annually__c = totalGM;
            }
            if(totalPM != 0){
                action.Unadj_Expected_Annual_Impact__c = totalPM;
            }
            // check defaults for reason for losses
            if(CheckReasonforLosses(action)){
                setDefaultReasonforLosses(action);
            }    
            
            action.FY1ExpectedUnit__c = totalVolumeFY1;
            action.FY2ExpectedUnit__c = totalVolumeFY2;
            action.FY1Name__c = totalFY1Name;
            action.FY2Name__c = totalFY2Name;           
            
            Integer intDateDiff1 = (action.Benefit_End_Date__c == null || action.CloseDate == null ? 12 : (action.CloseDate.monthsBetween(action.Benefit_End_Date__c)));
            Integer intMonthConsideration1 = (intDateDiff1 < 0 || intDateDiff1 >= 12? 12 : intDateDiff1 + 1);
                
            for(Monthly_Expected_Values__c objMonthlyExpected : lstMontlyExpected){
                objMonthlyExpected.Action1__c = action.id;
                objMonthlyExpected.CurrencyIsoCode = action.CurrencyIsoCode;            
                    if(intMonthConsideration1 <= 0){                
                        objMonthlyExpected.inRange__c = false;
                    }else{                    
                        objMonthlyExpected.inRange__c = true;
                    }
                    intMonthConsideration1--;                                       
            }
        }

        Delete [Select Id From Monthly_Expected_Values__c Where Action1__c in: mMonthlyValues.keyset()]; 
        insert lstMontlyExpected;
        if(performDLMOperation){
            upsert mOpptstoUpdate.values();
        }else{
            mobjectstoUpsert.putAll(mOpptstoUpdate);
        }
        isDistrubuted = true;
        return mobjectstoUpsert;
    }

    private static map<id, list<Monthly_Expected_Values__c>> getAllMonthlyValues(set<id> recordIDs){
        map<id, list<Monthly_Expected_Values__c>> oreturn =new  map<id, list<Monthly_Expected_Values__c>>();
        for(Monthly_Expected_Values__c item : [Select Id, Action1__c, Name, Date__c,Volumes__c, GM__c, PM__c, Distributed__c, InScope__c, InRange__c 
                    From Monthly_Expected_Values__c Where Action1__c in: recordIDs]){
            if(!oreturn.containskey(item.Action1__c)) {
                oreturn.put(item.Action1__c , new list<Monthly_Expected_Values__c>{item});
            }else{
                oreturn.get(item.Action1__c).add(item);
            }
        }
        return oreturn;
    }

    @testvisible
    private static list<Monthly_Expected_Values__c> getMonthlyValuesTHISMONTH(string recordID ,map<id, list<Monthly_Expected_Values__c>> mAllMonthlyValues  ){
        list<Monthly_Expected_Values__c> oreturn =  new list<Monthly_Expected_Values__c>();

        for(Monthly_Expected_Values__c item : mAllMonthlyValues.get(recordID)){
            Date thisMonth = Date.today().toStartOfMonth();
            if(item.Date__c < thisMonth){
                oreturn.add(item);
            }
        }
        
        return oreturn;
    }

    @testvisible
    private static list<Monthly_Expected_Values__c> getMonthlyValuesLASTMONTH(string recordID ,map<id, list<Monthly_Expected_Values__c>> mAllMonthlyValues  ){
        list<Monthly_Expected_Values__c> oreturn = new list<Monthly_Expected_Values__c>();

        for(Monthly_Expected_Values__c item : mAllMonthlyValues.get(recordID)){
            Date lastMonth = Date.today().addMonths(-1).toStartOfMonth();
            if(item.Date__c < lastMonth){
                oreturn.add(item);
            }
        }
        
        return oreturn;
    }
    public class wrapMonthlyValues{
        public wrapMonthlyValues(){}
        public  wrapMonthlyValues( string Id ,string DateValue,decimal Volume, decimal GM, decimal PM , boolean newRecord,Monthly_Expected_Values__c record  ){
            this.id = id;
            this.DateValue = DateValue;
            this.GM = gm;
            this.PM = pm;
            this.newRecord = newRecord;
            this.record = record;
        }
        @AuraEnabled  public string DateValue {get;set; }
        @AuraEnabled  public decimal Volume {get;set; }
        @AuraEnabled  public decimal GM {get;set; }
        @AuraEnabled  public decimal PM {get;set; }
        @AuraEnabled  public string Id {get;set; }
        @AuraEnabled  public boolean newRecord {get;set; }
        @AuraEnabled  public Monthly_Expected_Values__c record {get;set; }
    }
 
}