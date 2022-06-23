import { LightningElement, api,track } from 'lwc';
import runsoql from '@salesforce/apex/ctrlCustomTreeView.runSoql';
export default class CustomTreeView extends LightningElement {
    @api soqls=[];
    @api customclass = 'slds-tree';
    @api customrole = 'tree';
    @api ariallevel=1;
    @api parentFilter = [];
    @api deserializedSoqls = '';

    @track currentFilter = [];
    @track isloading = false;
    @track allitems = [];
    
    get _soqls(){
        if (this.deserializedSoqls !=''){
            return JSON.parse(this.deserializedSoqls);
        }
        return this.soqls;
    }
    get pickedupFields(){
        let returnedvalue = this.currentlevel?.sendpickupfieldsAs;
        if( returnedvalue!=undefined && returnedvalue!=null){
            return   returnedvalue;
        }else{
            return this.currentlevel.pickupfields;
        }
        
    }
    disconnectedCallback(){
        const selectEvent = new CustomEvent('dismitchitem', {
            detail: JSON.stringify(this.currentFilter)
        });
        this.dispatchEvent(selectEvent);
    }

    handledismitchItem(event){
        const selectEvent = new CustomEvent('dismitchitem', {
            detail: event.detail
        });
        this.dispatchEvent(selectEvent);
    }
    get currentlevel(){
        return this._soqls[ this._soqls.length< this.ariallevel? this._soqls.length-1 : this.ariallevel-1 ];
    }
    connectedCallback() {
        if(this._soqls.length>0){
            this.torunsoql(
                this.currentlevel.soql , 
                this.currentlevel.pickupfields,
                this.currentlevel?.sendpickupfieldsAs,
                this.currentlevel?.displayfields,
                this.currentlevel.showCheckbox,
                this.currentlevel?.isdraggable,
                this.currentlevel?.distinctValues,
                this.currentlevel?.recursive,
                this.parentFilter
            );
        }
    }

    get nextlevel(){
        return this.ariallevel +1;
    }
    handleDragStart(event){
        this.handlepickvalue(event);
        event.dataTransfer.setData("divId", JSON.stringify( this.currentFilter));
        console.log('handleDragStart ');
    }
    get canExpand(){
        return this.currentlevel.canExpand;
    }
    torunsoql(soql , pickupfields, sendpickupfieldsAs , displayfields , showCheckbox,  isdraggable, distinctValues, recursive , parentFilter){
        this.isloading = true;
        runsoql({strsql: soql , pickupFields: pickupfields, sendpickupfieldsAs: sendpickupfieldsAs , displayfields: displayfields, showCheckbox: showCheckbox, isdraggable: isdraggable , distinctValues: distinctValues, recursive: recursive , parentFilter: JSON.stringify(parentFilter) }).then(result => {
            result.forEach(item => {
                this.allitems.push(
                    {
                        ...item,
                        'expanded': false
                    }
                );
            });     
            this.isloading = false;
        }).catch(error => {
            this.loading = false;
            console.log('error>>'+ JSON.stringify(error));        
        });
    }

    handlepickvalue(event){

        let items = this.allitems.filter(element => element.Id ===  event.target.dataset.item );
        try{
            if(items.length>0){
                console.log('items filters:' + JSON.stringify(items[0].filters));
                this.currentFilter = [];
                items[0].filters.forEach(item => {
                    this.currentFilter.push(item);
                });     
                this.currentFilter.push(
                    {
                        fieldName:  this.pickedupFields,
                        fieldValue:  event.target.dataset.item
                    }
                );
            }
        }
        catch(e){
            alert(e);
        }

        console.log('currentFilter: '  + JSON.stringify(this.currentFilter));
    }
    handlelevel(event){
        let items = this.allitems.filter(element => element.Id ===  event.target.dataset.item );
        try{
            if(items.length>0){
                this.currentFilter = [];
                items[0].filters.forEach(item => {
                    this.currentFilter.push(item);
                });     
                this.currentFilter.push(
                    {
                        fieldName:  this.pickedupFields,
                        fieldValue:  event.target.dataset.item
                    }
                );
                items[0].expanded = !items[0].expanded;
                console.log('currentFilter: '  + JSON.stringify(this.currentFilter));
            }
        }
        catch(e){
            this.isloading = false;
            alert(e);
        }

    }

}