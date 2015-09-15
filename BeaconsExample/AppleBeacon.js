/**
 *
 * @providesModule AppleBeacon
 */

'use strict';

let React = require('react-native');

let {
  AppRegistry,
  StyleSheet,
  DeviceEventEmitter,
  ListView,
  NativeModules: {
    RNiBeacon,
  },
  Text,
  TouchableHighlight,
  View,
} = React;


var AppleBeacon = React.createClass({

  _rangeColor() {
    switch (this.props.proximity) {
      case 'immediate':
        return '#519548';
        break;
      case 'near':
        return '#F9CB42';
        break;
      case 'far':
      default:
        return '#E75943';
    }
  },

  render() {
    return (
      <View style={styles.wrapper}>
        <View style={{flexDirection: 'row'}}>
          <View style={[styles.rssi, {backgroundColor: this._rangeColor()}]}>
            <Text style={styles.rssiText}>{this.props.rssi}</Text>
          </View>
        </View>
        <View>
          <Text>Major: {this.props.major}</Text>
          <Text>Minor: {this.props.minor}</Text>
          <Text>Proximity: {this.props.proximity}</Text>
          <Text>Distance: {this.props.accuracy.toFixed(2)}m</Text>
        </View>
      </View>
    );
  }
});

var BeaconList = React.createClass({
  getInitialState: function() {
    return {
      dataSource: new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2})
    };
  },

  componentWillMount: function() {
    RNiBeacon.createBeaconRegion('E2C56DB5-DFFB-48D2-B060-D0F5A71096E0', '@blick.labs');
    RNiBeacon.startMonitoringForRegion();
    RNiBeacon.startRangingBeaconsInRegion();
    RNiBeacon.startUpdatingLocation();

    // Listen for beacon changes
    var subscription = DeviceEventEmitter.addListener('didRangeBeacons', (data) => {
      this.setState({
        dataSource: this.state.dataSource.cloneWithRows(data.beacons)
      });
    });
  },

  renderRow(rowData) {
    return <AppleBeacon {...rowData} style={styles.row} />
  },

  render() {
    return (
      <ListView
        automaticallyAdjustContentInsets={false}
        dataSource={this.state.dataSource}
        renderRow={this.renderRow}
      />
    );
  },
});


var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    backgroundColor: '#F5FCFF',
  },
  wrapper: {
    flexDirection: 'row',
    paddingRight: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#e9e9e9',
  },
  title: {
    paddingVertical: 3,
    paddingRight: 15,
    fontWeight: 'bold',
    fontSize: 16,
  },
  description: {
    color: "#B4AEAE",
    fontSize: 12,
    marginBottom: 5,
  },
  smallText: {
    fontSize: 11,
    textAlign: 'right',
    color: "#B4AEAE",
  },
  rssi: {
    width: 100,
    height: 100,
    marginRight: 10,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'green',
  },
  rssiText: {
    fontSize: 40,
    fontWeight: "100",
    color: 'white',
  }
});

module.exports = BeaconList;
