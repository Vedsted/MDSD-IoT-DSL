package sdu.mdsd.utils

import sdu.mdsd.ioT.Device
import java.util.Iterator
import java.util.ArrayList
import sdu.mdsd.ioT.EdgeDevice
import sdu.mdsd.ioT.FogDevice
import sdu.mdsd.ioT.CloudDevice
import java.util.List

class IoTUtils {
	
	/*
	 * Device hierarchy set.
	 * Uses BFS.
	 */
	def deviceHierarchyBFS(Device d) {
		val hierarchy = newLinkedHashSet
		
		var queue = new ArrayList<Device>();
		queue.add(d)
		
		while (queue.length > 0) {
			val current = queue.get(0)
			queue.remove(current)
			
			if (current != d) // Don't add the initial device to the hierarchy
				hierarchy.add(current)
			
			for (superType : current.superTypes) {
				if (!queue.contains(superType)) { // Do not add super types that is already in the queue
					queue.add(superType)
				}
			}
		}
		
		return hierarchy
	}
	
	def deviceHierarchyDFS(Device d) {
		val hierarchy = newLinkedHashSet
		
		var stack = new ArrayList<Device>();
		stack.add(d)
		
		while (stack.length > 0) {
			val current = stack.get(stack.length - 1) // Pop the last element
			stack.remove(current)
			
			if (current != d) { // Don't add the initial device to the hierarchy
				hierarchy.add(current)
			}
			
			for (superType : current.superTypes) {
				if (superType != current && !hierarchy.contains(superType)) { // Ignore cycles
					if (!stack.contains(superType)) { // Do not add super types that is already in the queue
						stack.add(superType)
					}
				}
			}
		}
		
		return hierarchy
	}
	
	def List<Device> deviceHierarchyDFS2(Device d) {
		d.deviceHierarchyDFS2(new ArrayList<Device>, new ArrayList<Device>)
	}
	
	def List<Device> deviceHierarchyDFS2(Device d, List<Device> discovered, List<Device> hierarchy) {
		
		discovered.add(d)
		hierarchy.add(d)
		
		for (v : d.superTypes) {
			if (!discovered.contains(v)) { // If "undiscovered"
				deviceHierarchyDFS2(v, discovered, hierarchy)
			}
		}
		
		
		return hierarchy
	}
	
	
	def deviceHierarchyVariables(Device d) {
		val h = d.deviceHierarchyDFS				
		return h.map[program.variables].flatten
	}
	
	def getNonAbstractDevices(Iterator<Device> devices) {
		return devices.filter[d | d.isAbstract == false]
	}
	
	def getFriendlyTypeName(Device d) {
		switch d {
			EdgeDevice: "Edge"
			FogDevice: "Fog"
			CloudDevice: "Cloud"
			default: "Unknown friendly type name"
		}
	}
	
	/*
     * Finds all of a given type within a device
     */
    def <E> findTypesInHierarchy(Device device, Class<E> cls){findTypesInHierarchy(device, cls, new ArrayList<E>())}
    
    /*
     * Finds all of a given type within a device
     */
    def <E> List<E> findTypesInHierarchy(Device device, Class<E> cls, List<E> found) {
        
        val hierarchy = device.deviceHierarchyDFS2.reverse
        
        // Check extending
        hierarchy.forEach[a| found.addAll(a.eAllContents.filter(cls).toList)]
        return found
    }
}