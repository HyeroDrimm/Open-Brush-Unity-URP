// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace TiltBrushToolkit {

public class BrushManifest : ScriptableObject {
  [SerializeField] private BrushDescriptor[] m_Brushes = null;
  private Dictionary<Guid, BrushDescriptor> m_ByGuid;
  private ILookup<string, BrushDescriptor> m_ByName;

  public IEnumerable<BrushDescriptor> AllBrushes {
    get { return m_Brushes; }
  }

  public Dictionary<Guid, BrushDescriptor> BrushesByGuid {
    get {
      if (m_ByGuid == null) {
        m_ByGuid = m_Brushes.ToDictionary(desc => (Guid)desc.m_Guid);
      }
      return m_ByGuid;
    }
  }

  public ILookup<string, BrushDescriptor> BrushesByName {
    get {
      if (m_ByName == null) {
        m_ByName = m_Brushes.ToLookup(desc => desc.m_DurableName);
      }
      return m_ByName; 
    }
  }

#if true
#if UNITY_EDITOR
  [UnityEditor.MenuItem("Tilt Brush/Update Manifest")]
  public static void MenuItem_UpdateManifest() {
    BrushManifest manifest = TbtSettings.BrushManifest;
    manifest.m_Brushes = UnityEditor.AssetDatabase.FindAssets("t:BrushDescriptor")
        .Select(g => UnityEditor.AssetDatabase.GUIDToAssetPath(g))
        .Select(p => UnityEditor.AssetDatabase.LoadAssetAtPath<BrushDescriptor>(p))
        .ToArray();
    UnityEditor.EditorUtility.SetDirty(manifest);
  }
#endif
#endif
}

}
