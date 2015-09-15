/**
 *
 * @providesModule EddystoneView
 */

'use strict';

let React = require('react-native');

let {
  AppRegistry,
  StyleSheet,
  DeviceEventEmitter,
  ListView,
  NativeModules: {
    RNEddystone,
  },
  Text,
  TouchableHighlight,
  View,
} = React;

var Buffer = require('buffer').Buffer;

var ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});

var EddyStoneUID = React.createClass({
  render() {
    return (
      <View>
        <Text>txPower: {this.props.beacon.txPower}</Text>
        <Text>type: {this.props.beacon.type}</Text>
        <Text>Namespace: {this.props.beacon.namespaceID}</Text>
        <Text>Instance: {this.props.beacon.instanceID}</Text>
      </View>
    );
  }
});

var EddyStoneURL = React.createClass({
  render() {
    return (
      <View>
        <Text>txPower: {this.props.beacon.txPower}</Text>
        <Text>type: {this.props.beacon.type}</Text>
        <Text>URL: {this.props.beacon.url}</Text>
      </View>
    );
  }
});

var EddystoneView = React.createClass({

  _rangeColor() {
    let rssi = this.props.rssi;
    // this._calculate();
    if (rssi >= -55) {
      return '#519548';
    } else if (rssi >= -65) {
      return '#F9CB42';
    } else if (rssi >= -75) {
      return '#E75943';
    } else {
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
          {(this.props.type === 'uid') && <EddyStoneUID beacon={this.props} />}
          {(this.props.type === 'url') && <EddyStoneURL beacon={this.props} />}
      </View>
    );
  }
});

var EddystoneList = React.createClass({
  getInitialState() {
    return {
      dataSource: ds.cloneWithRows([]),
    };
  },

  componentWillMount() {
    RNEddystone.startScanning();
    // RNEddystone.setOnLostTimeout(5); // Default 15.0

    var didFindBeacon = DeviceEventEmitter.addListener('didFindBeacon', (beacon) => {
      // console.log('FOUND', beacon);
    });

    var didUpdateBeacon = DeviceEventEmitter.addListener('didUpdateBeacon', (beacons) => {
      // console.log('UPDATE', beacons);

      this.setState({
        dataSource: ds.cloneWithRows(beacons)
      });
    });

    var didLoseBeacon = DeviceEventEmitter.addListener('didLoseBeacon', (beacon) => {
      // console.log('LOSE', beacon);
    });
  },

  componentWillUnmount() {
    RNEddyStone.stopScanning();
    didFindBeacon.remove();
    didUpdateBeacon.remove();
    didLoseBeacon.remove();
  },

  renderRow(rowData) {
    if(rowData.tlm) {
      let data = new Buffer(rowData.tlm.frameData, 'hex');
      let test = {
        version: data.readUInt8(1),
        vbatt: data.readUInt16BE(2),
        temp: data.readInt16BE(4) / 256,
        advCnt: data.readUInt32BE(6),
        secCnt: data.readUInt32BE(10)
      };
      
    }
    return <EddystoneView {...rowData} style={styles.row} />
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
    textAlign: 'left',
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

module.exports = EddystoneList;
