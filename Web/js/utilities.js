// fix bootstrap-table icons
window.icons = {
  refresh: 'fa-sync',
  toggle: 'fa-id-card',
  columns: 'fa-columns',
  clear: 'fa-trash'
};

function formatMiners(data) {
    // This function can alter the returned data before building the table, formatting it in a way
    // that is easier to display and manipulate in a table
    $.each(data, function(index, item) {
      // Format miner link
      if (item.MinerUri) {
        item.tName = "<a href='" + item.MinerUri + "' target ='_blank'>" + item.Name + "</a>";
      } else {
        item.tName = item.Name;
      }
  
      // Format the device(s)
        if (item.DeviceName) {
        item.tDevices = item.DeviceName.toString();
      }
      else {
        item.tDevices = '';
      }

      // Format the algorithm data
      if (item.Algorithm.length > 0) {
        item.tPrimaryAlgorithm = item.Algorithm[0];
      }
      if (item.Algorithm.length > 1) {
        item.tSecondaryAlgorithm = item.Algorithm[1];
      }

      // Format the pool data
      if (item.Workers.length > 0) {
        item.tPrimaryMinerFee = item.Workers[0].Fee;
        item.tPrimarySpeed = item.Workers[0].Speed;
        if (item.Workers[0].Pool) {
          item.tPrimaryPool = item.Workers[0].Pool.Name;
          item.tPrimaryPoolFee = item.Workers[0].Pool.Fee;
        }
      }
      if (item.Workers.length > 1) {
        item.tSecondaryMinerFee = item.Workers[1].Fee;
        item.tSecondarySpeed = item.Workers[1].Speed;
        if (item.Workers[1].Pool) {
          item.tSecondaryPool = item.Workers[1].Pool.Name;
          item.tSecondaryPoolFee = item.Workers[1].Pool.Fee;
        }
      }

      // Format margin of error
      item.tEarningAccuracy = formatPercent(item.Earning_Accuracy)

      // Format the live speed(s)
      item.tPrimarySpeedLive = item.Speed_Live[0];
      item.tSecondarySpeedLive = item.Speed_Live[1];

      // Format Total Mining Duration (TimeSpan)
      item.tTotalMiningDuration = formatTimeSpan(item.TotalMiningDuration);

      // Format the reason(s)
      if (item.Reason) {
        item.tReason = item.Reason.join('; ');
      }
      else {
        item.tReason = '';
      }

      // Format status
      const enumstatus = ["Running", "Idle", "Failed"];
      item.tStatus = enumstatus[item.Status];
  });
  return data;
}

function formatTimeSince(value) {
  var date = new Date(value);
  var localtime = new Date().getTime();
  var seconds = Math.floor((new Date() - date) / 1000);
  if (isNaN(seconds)) {
      seconds = Math.floor((localtime - parseInt(value.replace("/Date(", '').replace(")/", ''))) / 1000);
  }
  var interval = Math.floor(seconds / 31536000);
  if (interval > 1) {
    return interval + ' years ago';
  } else if (interval == 1) {
    return interval + ' year ago';
  }
  interval = Math.floor(seconds / 2592000);
  if (interval > 1) {
    return interval + ' months ago';
  } else if (interval == 1) {
    return interval + ' month ago';
  }
  interval = Math.floor(seconds / 86400);
  if (interval > 1) {
    return interval + ' days ago';
  } else if (interval == 1) {
    return interval + ' day ago';
  }
  interval = Math.floor(seconds / 3600);
  if (interval > 1) {
    return interval + ' hours ago';
  } else if (interval == 1) {
    return interval + ' hour ago';
  }
  interval = Math.floor(seconds / 60);
  if (interval > 1) {
    return interval + ' minutes ago';
  } else if (interval == 1) {
    return interval + ' minute ago';
  }
  if (seconds > 0) {
    return Math.floor(seconds) + ' seconds ago';
  } else {
    return 'just now';
  }
}

function formatHashRateValue(value) {
  var sizes = ['H/s', 'kH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s', 'ZH/s', 'YH/s'];
  if (value == '') return ''
  if (isNaN(value)) return '-';
  if (value == "0.0") return '-';
  if (value > 0 && value <= 1) return value.toFixed(2) + ' H/s';
  var i = Math.floor(Math.log(value) / Math.log(1000));
  if (value >= 1) return parseFloat((value / Math.pow(1000, i)).toFixed(2)) + ' ' + sizes[i];
  return '-';
};

function formatHashRate(value) {
  if (Array.isArray(value)) {
    return value.map(formatHashRate).toString();
  } else {
    return formatHashRateValue(value);
  }
}

function formatmBTC(value) {
  if (value === '') return "-";
  if (value > 0) return parseFloat(value * rate / 1000).toFixed(8);
  if (value == 0) return parseFloat(0).toFixed(8);
  if (value < 0) return parseFloat(value * rate / 1000).toFixed(8);
  return '-';
};

function formatBTC(value) {
  if (value === '') return "-";
  if (value > 0) return parseFloat(value * rate).toFixed(8);
  if (value == 0) return parseFloat(0).toFixed(8);
  if (value < 0) return parseFloat(value * rate).toFixed(8);
  return '-';
};

function formatDate(value) {
  if (value === '') return "N/A";
  if (Date.parse(value)) { return (new Date(value).toLocaleString(navigator.language)) };
  if (value == "Unknown") { return "N/A" }
  if (value == null) { return "N/A" }
  return value;
};

function formatWatt(value) {
  if (value === '') return "-";
  if (value > 0) return parseFloat(value).toFixed(2) + ' W';
  if (value == 0) return parseFloat(0).toFixed(2) + ' W';
  return '-';
};

function formatPercent(value) {
  if (value === '') return "-";
  if (isNaN(value)) return '-';
  return parseFloat(value * 100).toFixed(2) + ' %';
};

function formatPrices(value) {
  if (value === '') return "-";
  if (isNaN(value)) return '-';
  return (value * 1000000000).toFixed(10);
};

function formatArrayAsString(value) {
  if (value === '') return ''
  if (value == null) return '';
  return value.sort().join('; <br>');
};

function formatGB(value) {
  if (value > 0) return parseFloat(value / 1024 / 1024 / 1024).toFixed(3) + ' GB';
  return '-';
};

function formatMinerHashRatesAlgorithms(value) {
 return Object.keys(value).toString();
};

function formatMinerHashRatesValues(value) {
  hashrates = [];
  for (var property in value) {
    hashrates.push(formatHashRateValue(value[property]));
  }
  return hashrates.toString();
}

function detailFormatter(index, row) {
  var html = [];
  $.each(row, function (key, value) {
    if (typeof value === 'string') {
      html.push(`<p class="mb-0"><b>${key}:</b> ${JSON.stringify(value).replaceAll("\\\\", "\\")}</p>`);
    } else {
      html.push(`<p class="mb-0"><b>${key}:</b> ${JSON.stringify(value)}</p>`);
    }
  });
  return html.join('');
}

function formatBytes(bytes) {
  if (isNaN(bytes)) return '-';
  if (bytes == null) return '-';
  if (bytes == 0) return '0 Bytes';
  decimals = 2
  var k = 1024,
  dm = decimals || 2,
  sizes = ['Bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
  i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

function formatTimeSpan(timespan) {
  var duration = '';
  if (timespan) {
    duration = timespan.Days + ' days ';
    duration = duration + timespan.Hours + ' hrs ';
    duration = duration + timespan.Minutes + ' min ';
    duration = duration + timespan.Seconds + ' sec ';
    return duration
  }
  else {
    return '-'
  }
}

function createUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
     var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
     return v.toString(16);
  });
}