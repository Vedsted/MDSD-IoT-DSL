package sdu.mdsd.utils

import sdu.mdsd.ioT.Device
import java.util.HashSet
import java.util.Iterator

class IoTUtils {
	
	/*
	 * Device hierarchy set.
	 * Uses BFS.
	 */
	def deviceHierarchy(Device d) {
		val hierarchy = newLinkedHashSet
		
		var queue = new HashSet<Device>();
		queue.add(d)
		
		while (queue.length > 0) {
			val current = queue.get(0)
			queue.remove(current)
			
			if (current != d) // Don't add the initial device to the hierarchy
				hierarchy.add(current)
			
			for (superType : current.superTypes) {
				queue.add(superType)
			}
		}
		
		return hierarchy
	}
	
	
	def deviceHierarchyVariables(Device d) {
		/*switch d {
			EdgeDevice: {
				val h = d.deviceHierarchy				
				return h.map[program.variables].flatten
			}
			FogDevice: {
				val h = d.deviceHierarchy.map[program.variables].flatten
				return h
			}
			CloudDevice: {
				val h = d.deviceHierarchy.map[program.variables].flatten
				return h
			}
		}*/
		val h = d.deviceHierarchy				
		return h.map[program.variables].flatten
	}
	
	def getNonAbstractDevices(Iterator<Device> devices) {
		return devices.filter[d | d.isAbstract == false]
	}
}