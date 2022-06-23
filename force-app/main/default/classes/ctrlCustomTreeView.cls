public without sharing  class ctrlCustomTreeView {

    @AuraEnabled 
    public static list<wrapperItems> runSoql(string strsql, string pickupFields, string sendpickupfieldsAs , string displayfields, boolean showCheckbox, boolean isdraggable, boolean distinctValues, boolean recursive, string parentFilter){
        recursive = recursive==null?false:recursive;
        list<wrapperItems> objreturn = new list<wrapperItems>();
        list<wrapperFilter> filters = (list<wrapperFilter>) JSON.deserialize(parentFilter, list<wrapperFilter>.class);
        list<wrapperFilter> filters_temp = new list<wrapperFilter> ();
        string strfilter = '';
        if(recursive && filters.size()>0){
            filters_temp = new list<wrapperFilter>{filters[filters.size()-1]};
        }else{
            filters_temp = filters;
        }
        for(wrapperFilter it:filters_temp){
            strfilter = strfilter + it.fieldName + '=' +  '\'' + it.fieldValue + '\''+  ' and ' ;
        }
        if(strfilter.length()>0){
            strfilter = strfilter.mid(0,strfilter.length()-4);
        }
        strsql = strsql.replace('@filter' , strfilter);
        system.debug('strsql: '+strsql);
        set<string> sItems = new set<string>();
        for(sobject item: database.query(strsql)){
            string tempstrID = string.valueof(item.get(pickupFields)) ;
            string tempstrValue = string.valueof(item.get((displayfields!=null && displayfields !=''?displayfields: pickupFields))) ;
            if(distinctValues==true ){
                if(!sItems.contains(tempstrID) ){
                    objreturn.add(new wrapperItems(tempstrID,tempstrValue,showCheckbox,isdraggable,filters) );
                    sitems.add(tempstrID);
                }
            }else{
                objreturn.add(new wrapperItems(tempstrID,tempstrValue,showCheckbox,isdraggable,filters) );
            }
        }        
        return objreturn;
    }

    public class wrapperItems{
        public wrapperItems(string ID , string value, boolean showCheckbox, boolean isdraggable, list<wrapperFilter> filters){
            this.Id = id;
            this.value = value;
            this.showCheckbox = showCheckbox;
            this.isdraggable = isdraggable;
            this.filters = filters;
        }
        @AuraEnabled public string Id {get;set;}
        @AuraEnabled public boolean showCheckbox {get;set;}
        @AuraEnabled public list<wrapperFilter> filters {get;set;}
        @AuraEnabled public boolean isdraggable  {get;set;}        
        @AuraEnabled public string value {get;set;}
    }
    public class wrapperFilter{
        public wrapperFilter(string name, string value){
            this.fieldName = name;
            this.fieldValue = value;

        }
        @AuraEnabled public string fieldName {get;set;}
        @AuraEnabled public string fieldValue {get;set;}
    }

}