String shortenAddress(String? address, {int start = 6, int end = 4}) {
  if (address == null || address.isEmpty) return '';
  if (address.length <= start + end) return address;
  return '${address.substring(0, start)}...${address.substring(address.length - end)}';
}
