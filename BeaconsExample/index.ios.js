/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
// let RFDuinoContainer = require('./RFDuinoContainer');
var AppleBeacon = require('AppleBeacon');
var EddystoneView = require('EddystoneView');

var ScrollableTabView = require('react-native-scrollable-tab-view');

var {
  AppRegistry,
  StyleSheet,
} = React;

var BeaconsExample = React.createClass({
  render() {
    return (
      <ScrollableTabView edgeHitWidth={50}>
        <AppleBeacon tabLabel="iBeacon" />
        <EddystoneView tabLabel="EddyStone" />
      </ScrollableTabView>    
    );
  }
});

AppRegistry.registerComponent('BeaconsExample', () => BeaconsExample);
